import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'user_bootstrap.dart';
import 'local_data_cache_service.dart';
import 'sync_status_service.dart';

class BudgetService {
  static const int budgetFetchLimit = 100;
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final LocalDataCacheService _cache = LocalDataCacheService();

  // Create new budget
  Future<void> createBudget(Budget budget) async {
    try {
      debugPrint('🔵 BUDGET SERVICE: Creating budget');
      debugPrint('🔵 Budget: ${budget.name} - \$${budget.amount}');
      debugPrint('🔵 Category: ${budget.category}');
      debugPrint('🔵 Period: ${budget.period.name}');

      // Ensure user document exists
      await _ensureUserExists(budget.userId);

      // Generate ID if not provided
      final budgetId = budget.id.isEmpty ? _uuid.v4() : budget.id;
      final budgetToSave = budget.copyWith(id: budgetId);

      await _cache.upsertBudget(budgetToSave.userId, budgetToSave);

      await SyncStatusService().track(() => _firestore
          .collection('budgets')
          .doc(budgetId)
          .set(budgetToSave.toJson()));

      debugPrint('✅ BUDGET SERVICE: Budget created successfully');
    } catch (e) {
      debugPrint('❌ BUDGET SERVICE: Error creating budget: $e');
      throw Exception('Failed to create budget: $e');
    }
  }

  // Update budget
  Future<void> updateBudget(Budget budget) async {
    try {
      debugPrint('🔵 BUDGET SERVICE: Updating budget');
      debugPrint('🔵 Budget ID: ${budget.id}');

      await SyncStatusService().track(() => _firestore
          .collection('budgets')
          .doc(budget.id)
          .update(budget.toJson()));
      await _cache.upsertBudget(budget.userId, budget);

      debugPrint('✅ BUDGET SERVICE: Budget updated successfully');
    } catch (e) {
      debugPrint('❌ BUDGET SERVICE: Error updating budget: $e');
      throw Exception('Failed to update budget: $e');
    }
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId, {String? userId}) async {
    try {
      debugPrint('🔵 BUDGET SERVICE: Deleting budget');
      debugPrint('🔵 Budget ID: $budgetId');

      await SyncStatusService()
          .track(() => _firestore.collection('budgets').doc(budgetId).delete());
      if (userId != null) {
        await _cache.removeBudget(userId, budgetId);
      }

      debugPrint('✅ BUDGET SERVICE: Budget deleted successfully');
    } catch (e) {
      debugPrint('❌ BUDGET SERVICE: Error deleting budget: $e');
      throw Exception('Failed to delete budget: $e');
    }
  }

  // Get user budgets
  Future<List<Budget>> getUserBudgets(String userId) async {
    try {
      debugPrint('🔵 BUDGET SERVICE: Getting budgets for user: $userId');

      // Ensure user document exists
      await _ensureUserExists(userId);

      final querySnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .limit(budgetFetchLimit)
          .get();

      final budgets = querySnapshot.docs.map((doc) {
        try {
          debugPrint('🔵 BUDGET SERVICE: Parsing budget document: ${doc.id}');
          debugPrint('🔵 BUDGET SERVICE: Document data: ${doc.data()}');
          return Budget.fromJson(doc.data());
        } catch (e) {
          debugPrint(
              '❌ BUDGET SERVICE: Error parsing budget document ${doc.id}: $e');
          debugPrint('❌ BUDGET SERVICE: Document data: ${doc.data()}');
          rethrow;
        }
      }).toList();

      // Sort by creation date (newest first)
      budgets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      await _cache.saveBudgets(userId, budgets);

      debugPrint('✅ BUDGET SERVICE: Found ${budgets.length} budgets');
      return budgets;
    } catch (e) {
      debugPrint('❌ BUDGET SERVICE: Error getting budgets: $e');
      final cached = await _cache.loadBudgets(userId);
      debugPrint(
          'ℹ️ BUDGET SERVICE: Returning ${cached.length} cached budgets');
      return cached;
    }
  }

  // Process budget rollovers
  Future<void> processBudgetRollovers(String userId) async {
    try {
      debugPrint(
          '🔵 BUDGET SERVICE: Processing budget rollovers for user: $userId');

      final budgets = await getUserBudgets(userId);

      for (final budget in budgets) {
        if (budget.enableRollover && budget.isExpired && budget.remaining > 0) {
          await _processBudgetRollover(budget);
        }
      }

      debugPrint('✅ BUDGET SERVICE: Budget rollovers processed');
    } catch (e) {
      debugPrint('❌ BUDGET SERVICE: Error processing budget rollovers: $e');
      throw Exception('Failed to process budget rollovers: $e');
    }
  }

  // Recalculate all budget spent amounts from transactions
  Future<void> recalculateBudgetSpent(String userId) async {
    try {
      debugPrint(
          '🔵 BUDGET SERVICE: Recalculating budget spent for user: $userId');

      // Ensure user document exists
      await _ensureUserExists(userId);

      // Get all transactions for the user
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'expense')
          .get();

      final transactions = transactionsQuery.docs
          .map((doc) => Transaction.fromJson(doc.data()))
          .toList();

      // Get all budgets for the user
      final budgetsQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      final budgets =
          budgetsQuery.docs.map((doc) => Budget.fromJson(doc.data())).toList();

      // Use a batch for atomic updates
      final batch = _firestore.batch();

      // Index active budgets by ID so each transaction is a O(1) lookup
      // instead of a linear scan (was O(transactions * budgets)).
      final activeBudgetIds = {
        for (final budget in budgets)
          if (budget.isActive) budget.id: budget,
      };

      // Create a map to track spent amounts for each budget
      final Map<String, double> budgetSpentMap = {
        for (final budget in budgets) budget.id: 0.0,
      };

      // Calculate spent amounts from transactions
      for (final transaction in transactions) {
        // Only process transactions with budget assignments
        if (transaction.isActive &&
            transaction.budgetId != null &&
            transaction.budgetId!.isNotEmpty &&
            activeBudgetIds.containsKey(transaction.budgetId)) {
          budgetSpentMap[transaction.budgetId!] =
              (budgetSpentMap[transaction.budgetId!] ?? 0.0) +
                  transaction.amount;
        }
      }

      // Update all budgets with calculated spent amounts
      for (final budget in budgets) {
        final budgetRef = _firestore.collection('budgets').doc(budget.id);
        batch.update(budgetRef, {'spent': budgetSpentMap[budget.id] ?? 0.0});
      }

      // Commit the batch
      await SyncStatusService().track(() => batch.commit());

      debugPrint('✅ BUDGET SERVICE: Budget spent amounts recalculated');
    } catch (e) {
      debugPrint('❌ BUDGET SERVICE: Error recalculating budget spent: $e');
      throw Exception('Failed to recalculate budget spent: $e');
    }
  }

  Future<void> _ensureUserExists(String userId) =>
      ensureUserExists(_firestore, userId, logTag: 'BUDGET SERVICE');

  // Private method to process budget rollover
  Future<void> _processBudgetRollover(Budget budget) async {
    try {
      debugPrint(
          '🔵 BUDGET SERVICE: Processing rollover for budget: ${budget.name}');

      // Calculate rollover amount
      final rolloverAmount = budget.remaining > 0 ? budget.remaining : 0.0;

      // Create new budget period
      final newStartDate = budget.endDate.add(const Duration(days: 1));
      final newEndDate = _calculateNextPeriodEnd(budget.period, newStartDate);

      // Create new budget with rollover
      final newBudget = Budget(
        id: _uuid.v4(),
        userId: budget.userId,
        name: budget.name,
        amount: budget.amount,
        period: budget.period,
        category: budget.category,
        startDate: newStartDate,
        endDate: newEndDate,
        spent: 0.0,
        isActive: true,
        createdAt: DateTime.now(),
        enableRollover: budget.enableRollover,
        rolloverAmount: rolloverAmount,
      );

      // Deactivate old budget and create new one
      final batch = _firestore.batch();

      final oldBudgetRef = _firestore.collection('budgets').doc(budget.id);
      batch.update(oldBudgetRef, {'isActive': false});

      final newBudgetRef = _firestore.collection('budgets').doc(newBudget.id);
      batch.set(newBudgetRef, newBudget.toJson());

      await SyncStatusService().track(() => batch.commit());

      debugPrint(
          '✅ BUDGET SERVICE: Rollover processed - \$$rolloverAmount carried over');
    } catch (e) {
      debugPrint('❌ BUDGET SERVICE: Error processing budget rollover: $e');
      throw Exception(
          'Failed to process rollover for budget "${budget.name}": $e');
    }
  }

  // Private method to calculate next period end date
  DateTime _calculateNextPeriodEnd(BudgetPeriod period, DateTime startDate) {
    switch (period) {
      case BudgetPeriod.daily:
        return startDate.add(const Duration(days: 1));
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  // Generate unique ID
  String generateId() {
    return _uuid.v4();
  }
}
