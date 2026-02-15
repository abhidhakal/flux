import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create new budget
  Future<void> createBudget(Budget budget) async {
    try {
      print('🔵 BUDGET SERVICE: Creating budget');
      print('🔵 Budget: ${budget.name} - \$${budget.amount}');
      print('🔵 Category: ${budget.category}');
      print('🔵 Period: ${budget.period.name}');

      // Ensure user document exists
      await _ensureUserExists(budget.userId);

      // Generate ID if not provided
      final budgetId = budget.id.isEmpty ? _uuid.v4() : budget.id;
      final budgetToSave = budget.copyWith(id: budgetId);

      await _firestore
          .collection('budgets')
          .doc(budgetId)
          .set(budgetToSave.toJson());
      
      print('✅ BUDGET SERVICE: Budget created successfully');
      
    } catch (e) {
      print('❌ BUDGET SERVICE: Error creating budget: $e');
      throw Exception('Failed to create budget: $e');
    }
  }

  // Update budget
  Future<void> updateBudget(Budget budget) async {
    try {
      print('🔵 BUDGET SERVICE: Updating budget');
      print('🔵 Budget ID: ${budget.id}');

      await _firestore
          .collection('budgets')
          .doc(budget.id)
          .update(budget.toJson());
      
      print('✅ BUDGET SERVICE: Budget updated successfully');
      
    } catch (e) {
      print('❌ BUDGET SERVICE: Error updating budget: $e');
      throw Exception('Failed to update budget: $e');
    }
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      print('🔵 BUDGET SERVICE: Deleting budget');
      print('🔵 Budget ID: $budgetId');

      await _firestore
          .collection('budgets')
          .doc(budgetId)
          .delete();
      
      print('✅ BUDGET SERVICE: Budget deleted successfully');
      
    } catch (e) {
      print('❌ BUDGET SERVICE: Error deleting budget: $e');
      throw Exception('Failed to delete budget: $e');
    }
  }

  // Get user budgets
  Future<List<Budget>> getUserBudgets(String userId) async {
    try {
      print('🔵 BUDGET SERVICE: Getting budgets for user: $userId');
      
      // Ensure user document exists
      await _ensureUserExists(userId);
      
      final querySnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      final budgets = querySnapshot.docs
          .map((doc) {
            try {
              print('🔵 BUDGET SERVICE: Parsing budget document: ${doc.id}');
              print('🔵 BUDGET SERVICE: Document data: ${doc.data()}');
              return Budget.fromJson(doc.data());
            } catch (e) {
              print('❌ BUDGET SERVICE: Error parsing budget document ${doc.id}: $e');
              print('❌ BUDGET SERVICE: Document data: ${doc.data()}');
              rethrow;
            }
          })
          .toList();
      
      // Sort by creation date (newest first)
      budgets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ BUDGET SERVICE: Found ${budgets.length} budgets');
      return budgets;
      
    } catch (e) {
      print('❌ BUDGET SERVICE: Error getting budgets: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Get active budgets for user
  Future<List<Budget>> getActiveBudgets(String userId) async {
    try {
      print('🔵 BUDGET SERVICE: Getting active budgets for user: $userId');
      
      // Ensure user document exists
      await _ensureUserExists(userId);
      
      final querySnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final budgets = querySnapshot.docs
          .map((doc) => Budget.fromJson(doc.data()))
          .toList();
      
      print('✅ BUDGET SERVICE: Found ${budgets.length} active budgets');
      return budgets;
      
    } catch (e) {
      print('❌ BUDGET SERVICE: Error getting active budgets: $e');
      return [];
    }
  }

  // Process budget rollovers
  Future<void> processBudgetRollovers(String userId) async {
    try {
      print('🔵 BUDGET SERVICE: Processing budget rollovers for user: $userId');
      
      final budgets = await getUserBudgets(userId);
      
      for (final budget in budgets) {
        if (budget.enableRollover && budget.isExpired && budget.remaining > 0) {
          await _processBudgetRollover(budget);
        }
      }
      
      print('✅ BUDGET SERVICE: Budget rollovers processed');
      
    } catch (e) {
      print('❌ BUDGET SERVICE: Error processing budget rollovers: $e');
    }
  }

  // Recalculate all budget spent amounts from transactions
  Future<void> recalculateBudgetSpent(String userId) async {
    try {
      print('🔵 BUDGET SERVICE: Recalculating budget spent for user: $userId');
      
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

      final budgets = budgetsQuery.docs
          .map((doc) => Budget.fromJson(doc.data()))
          .toList();

      // Use a batch for atomic updates
      final batch = _firestore.batch();

      // Create a map to track spent amounts for each budget
      final Map<String, double> budgetSpentMap = {};
      
      // Initialize all budgets with 0 spent
      for (final budget in budgets) {
        budgetSpentMap[budget.id] = 0.0;
      }

      // Calculate spent amounts from transactions
      for (final transaction in transactions) {
        // Only process transactions with budget assignments
        if (transaction.budgetId != null && transaction.budgetId!.isNotEmpty) {
          final matchingBudget = budgets.firstWhere(
            (budget) => budget.id == transaction.budgetId && budget.isActive,
            orElse: () => Budget(
              id: '',
              userId: '',
              name: '',
              amount: 0,
              period: BudgetPeriod.monthly,
              category: '',
              startDate: DateTime.now(),
              endDate: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          );

          if (matchingBudget.id.isNotEmpty) {
            budgetSpentMap[matchingBudget.id] = 
                (budgetSpentMap[matchingBudget.id] ?? 0.0) + transaction.amount;
          }
        }
      }

      // Update all budgets with calculated spent amounts
      for (final budget in budgets) {
        final budgetRef = _firestore.collection('budgets').doc(budget.id);
        batch.update(budgetRef, {'spent': budgetSpentMap[budget.id] ?? 0.0});
      }

      // Commit the batch
      await batch.commit();
      
      print('✅ BUDGET SERVICE: Budget spent amounts recalculated');
      
    } catch (e) {
      print('❌ BUDGET SERVICE: Error recalculating budget spent: $e');
      throw Exception('Failed to recalculate budget spent: $e');
    }
  }

  // Private method to ensure user document exists
  Future<void> _ensureUserExists(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        print('⚠️ BUDGET SERVICE: User not found, creating user document');
        // Create basic user document if it doesn't exist
        await _firestore
            .collection('users')
            .doc(userId)
            .set({
          'id': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'lastLoginAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('❌ BUDGET SERVICE: Error ensuring user exists: $e');
      // Don't throw here to prevent cascading failures
    }
  }

  // Private method to process budget rollover
  Future<void> _processBudgetRollover(Budget budget) async {
    try {
      print('🔵 BUDGET SERVICE: Processing rollover for budget: ${budget.name}');
      
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
      
      await batch.commit();
      
      print('✅ BUDGET SERVICE: Rollover processed - \$$rolloverAmount carried over');
      
    } catch (e) {
      print('❌ BUDGET SERVICE: Error processing budget rollover: $e');
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
