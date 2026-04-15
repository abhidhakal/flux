import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class TransactionService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Add transaction with automatic budget update
  Future<void> addTransaction(Transaction transaction) async {
    try {
      debugPrint('🔵 TRANSACTION SERVICE: Adding transaction');
      debugPrint('🔵 Transaction: ${transaction.title} - \$${transaction.amount}');
      debugPrint('🔵 Category: ${transaction.category}');
      debugPrint('🔵 Type: ${transaction.type.name}');

      // Generate ID if not provided
      final transactionId =
          transaction.id.isEmpty ? _uuid.v4() : transaction.id;
      final transactionToSave = transaction.copyWith(id: transactionId);

      // Use a batch to ensure atomic operations
      final batch = _firestore.batch();

      // Add transaction to Firestore
      final transactionRef =
          _firestore.collection('transactions').doc(transactionId);
      batch.set(transactionRef, transactionToSave.toJson());

      // If it's an expense, update the corresponding budget
      if (transactionToSave.isExpense && transactionToSave.isActive) {
        await _updateBudgetForTransaction(transactionToSave, batch);
      }

      // Commit the batch
      await batch.commit();

      debugPrint('✅ TRANSACTION SERVICE: Transaction added successfully');
      debugPrint('✅ Budget updated (if expense)');
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error adding transaction: $e');
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Update transaction with budget recalculation
  Future<void> updateTransaction(Transaction newTransaction) async {
    try {
      debugPrint('🔵 TRANSACTION SERVICE: Updating transaction');
      debugPrint('🔵 Transaction ID: ${newTransaction.id}');

      // Get the old transaction
      final oldTransactionDoc = await _firestore
          .collection('transactions')
          .doc(newTransaction.id)
          .get();

      if (!oldTransactionDoc.exists) {
        throw Exception('Transaction not found');
      }

      final oldTransaction = Transaction.fromJson(oldTransactionDoc.data()!);

      // Use a batch for atomic operations
      final batch = _firestore.batch();

      // Update transaction
      final transactionRef =
          _firestore.collection('transactions').doc(newTransaction.id);
      batch.update(transactionRef, newTransaction.toJson());

      // Handle budget updates
      await _handleBudgetUpdateForTransactionChange(
          oldTransaction, newTransaction, batch);

      // Commit the batch
      await batch.commit();

      debugPrint('✅ TRANSACTION SERVICE: Transaction updated successfully');
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error updating transaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Delete transaction with budget adjustment
  Future<void> deleteTransaction(String transactionId) async {
    try {
      debugPrint('🔵 TRANSACTION SERVICE: Deleting transaction');
      debugPrint('🔵 Transaction ID: $transactionId');

      // Get the transaction before deleting
      final transactionDoc =
          await _firestore.collection('transactions').doc(transactionId).get();

      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }

      final transaction = Transaction.fromJson(transactionDoc.data()!);

      // Use a batch for atomic operations
      final batch = _firestore.batch();

      // Delete transaction
      final transactionRef =
          _firestore.collection('transactions').doc(transactionId);
      batch.delete(transactionRef);

      // If it was an expense, adjust the budget
      if (transaction.isExpense && transaction.isActive) {
        await _adjustBudgetForDeletedTransaction(transaction, batch);
      }

      // Commit the batch
      await batch.commit();

      debugPrint('✅ TRANSACTION SERVICE: Transaction deleted successfully');
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error deleting transaction: $e');
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Get user transactions
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      debugPrint('🔵 TRANSACTION SERVICE: Getting transactions for user: $userId');

      // Ensure user document exists
      await _ensureUserExists(userId);
      await _migrateLegacyIncomeToTransactions(userId);

      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      final transactions = <Transaction>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] ??= doc.id;
          final transaction = Transaction.fromJson(data);
          if (transaction.isActive) {
            transactions.add(transaction);
          }
        } catch (e) {
          debugPrint(
            '❌ TRANSACTION SERVICE: Error parsing transaction ${doc.id}: $e',
          );
        }
      }

      transactions.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('✅ TRANSACTION SERVICE: Found ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error getting transactions: $e');
      return [];
    }
  }

  // Check if user has transactions for today
  Future<bool> hasTransactionsToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfTomorrow = startOfDay.add(const Duration(days: 1));

      // Fetch recent transactions for user (filtering in Dart to avoid index issues)
      // We sort by date descending to get the latest ones effectively
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      // Count only active transactions that were actually added today.
      final hasToday = querySnapshot.docs.any((doc) {
        final data = doc.data();
        if (data['isActive'] == false) return false;

        final timestamp = data['createdAt'] ?? data['date'];
        if (timestamp == null) return false;

        final addedAt = DateTime.parse(timestamp as String);
        return !addedAt.isBefore(startOfDay) && addedAt.isBefore(startOfTomorrow);
      });

      return hasToday;
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error checking today transactions: $e');
      return false;
    }
  }

  // Private method to update budget for new transaction
  Future<void> _updateBudgetForTransaction(
      Transaction transaction, firestore.WriteBatch batch) async {
    try {
      debugPrint('🔵 TRANSACTION SERVICE: Updating budget for transaction');

      // If no budgetId assigned, skip budget update
      if (transaction.budgetId == null || transaction.budgetId!.isEmpty) {
        debugPrint('⚠️ TRANSACTION SERVICE: No budget assigned to transaction');
        return;
      }

      debugPrint('🔵 Looking for budget with ID: ${transaction.budgetId}');

      // Find budget by ID
      final budgetDoc = await _firestore
          .collection('budgets')
          .doc(transaction.budgetId!)
          .get();

      if (!budgetDoc.exists) {
        debugPrint(
            '⚠️ TRANSACTION SERVICE: Budget not found with ID: ${transaction.budgetId}');
        return;
      }

      final budget = Budget.fromJson(budgetDoc.data()!);

      // Verify budget belongs to user and is active
      if (budget.userId != transaction.userId || !budget.isActive) {
        debugPrint(
            '⚠️ TRANSACTION SERVICE: Budget not active or belongs to different user');
        return;
      }

      debugPrint('✅ TRANSACTION SERVICE: Found budget: ${budget.name}');
      debugPrint('✅ Current spent: \$${budget.spent}');
      debugPrint('✅ Adding amount: \$${transaction.amount}');

      // Calculate new spent amount
      final newSpent = budget.spent + transaction.amount;

      // Update budget
      final budgetRef = _firestore.collection('budgets').doc(budget.id);
      batch.update(budgetRef, {'spent': newSpent});

      debugPrint('✅ TRANSACTION SERVICE: Budget updated - new spent: \$$newSpent');
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error updating budget: $e');
      throw Exception('Failed to update budget: $e');
    }
  }

  // Private method to handle budget updates for transaction changes
  Future<void> _handleBudgetUpdateForTransactionChange(
    Transaction oldTransaction,
    Transaction newTransaction,
    firestore.WriteBatch batch,
  ) async {
    try {
      debugPrint(
          '🔵 TRANSACTION SERVICE: Handling budget update for transaction change');

      // 1. Identify affected budget IDs
      final String? oldBudgetId =
          oldTransaction.isExpense && oldTransaction.isActive
              ? oldTransaction.budgetId
              : null;
      final String? newBudgetId =
          newTransaction.isExpense && newTransaction.isActive
              ? newTransaction.budgetId
              : null;

      // Case 1: No budgets involved
      if (oldBudgetId == null && newBudgetId == null) {
        debugPrint('⚠️ TRANSACTION SERVICE: No budgets affected');
        return;
      }

      // Case 2: Same budget - recalculate with net difference
      if (oldBudgetId == newBudgetId && oldBudgetId != null) {
        final budgetDoc =
            await _firestore.collection('budgets').doc(oldBudgetId).get();
        if (budgetDoc.exists) {
          final budget = Budget.fromJson(budgetDoc.data()!);
          if (budget.userId == newTransaction.userId && budget.isActive) {
            final netChange = newTransaction.amount - oldTransaction.amount;
            final newSpent = budget.spent + netChange;

            batch.update(budgetDoc.reference, {'spent': newSpent});
            debugPrint(
                '✅ TRANSACTION SERVICE: Updated single budget ${budget.name} with net change: \$$netChange');
          }
        }
        return;
      }

      // Case 3: Different budgets or moving to/from no budget
      // Handle subtraction from old budget
      if (oldBudgetId != null) {
        final oldBudgetDoc =
            await _firestore.collection('budgets').doc(oldBudgetId).get();
        if (oldBudgetDoc.exists) {
          final oldBudget = Budget.fromJson(oldBudgetDoc.data()!);
          if (oldBudget.userId == oldTransaction.userId && oldBudget.isActive) {
            batch.update(oldBudgetDoc.reference,
                {'spent': oldBudget.spent - oldTransaction.amount});
            debugPrint(
                '✅ TRANSACTION SERVICE: Subtracted amount from OLD budget: ${oldBudget.name}');
          }
        }
      }

      // Handle addition to new budget
      if (newBudgetId != null) {
        final newBudgetDoc =
            await _firestore.collection('budgets').doc(newBudgetId).get();
        if (newBudgetDoc.exists) {
          final newBudget = Budget.fromJson(newBudgetDoc.data()!);
          if (newBudget.userId == newTransaction.userId && newBudget.isActive) {
            batch.update(newBudgetDoc.reference,
                {'spent': newBudget.spent + newTransaction.amount});
            debugPrint(
                '✅ TRANSACTION SERVICE: Added amount to NEW budget: ${newBudget.name}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error handling budget update: $e');
      throw Exception('Failed to handle budget update: $e');
    }
  }

  // Private method to adjust budget for deleted transaction
  Future<void> _adjustBudgetForDeletedTransaction(
      Transaction transaction, firestore.WriteBatch batch) async {
    try {
      // If no budgetId assigned, skip budget update
      if (transaction.budgetId == null || transaction.budgetId!.isEmpty) {
        return;
      }

      final budgetDoc = await _firestore
          .collection('budgets')
          .doc(transaction.budgetId!)
          .get();

      if (budgetDoc.exists) {
        final budget = Budget.fromJson(budgetDoc.data()!);

        // Verify budget belongs to user and is active
        if (budget.userId == transaction.userId && budget.isActive) {
          final newSpent = budget.spent - transaction.amount;

          final budgetRef = _firestore.collection('budgets').doc(budget.id);
          batch.update(budgetRef, {'spent': newSpent});

          debugPrint(
              '✅ TRANSACTION SERVICE: Adjusted budget for deleted transaction');
        }
      }
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error adjusting budget: $e');
    }
  }

  // Generate unique ID
  String generateId() {
    return _uuid.v4();
  }

  Future<void> _migrateLegacyIncomeToTransactions(String userId) async {
    try {
      final legacyIncomeSnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .get();

      if (legacyIncomeSnapshot.docs.isEmpty) {
        return;
      }

      for (final legacyIncomeDoc in legacyIncomeSnapshot.docs) {
        final data = legacyIncomeDoc.data();
        final transactionId = (data['id'] as String?)?.isNotEmpty == true
            ? data['id'] as String
            : legacyIncomeDoc.id;
        final transactionRef =
            _firestore.collection('transactions').doc(transactionId);
        final existingTransaction = await transactionRef.get();

        if (existingTransaction.exists) {
          await legacyIncomeDoc.reference.delete();
          continue;
        }

        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final category = data['category'] as String? ?? 'Salary';
        final notes = data['notes'] as String? ?? '';
        final dateValue = data['date'] as String?;
        final createdAtValue =
            (data['createdAt'] as String?) ?? dateValue ?? DateTime.now().toIso8601String();

        final transaction = Transaction(
          id: transactionId,
          userId: data['userId'] as String? ?? userId,
          title: notes.trim().isNotEmpty ? notes.trim() : category,
          description: notes,
          amount: amount,
          type: TransactionType.income,
          category: category,
          budgetId: data['budgetId'] as String?,
          date: dateValue != null ? DateTime.parse(dateValue) : DateTime.now(),
          createdAt: DateTime.parse(createdAtValue),
          metadata: const {'migratedFrom': 'incomes'},
        );

        await transactionRef.set(transaction.toJson());
        await legacyIncomeDoc.reference.delete();
      }
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error migrating legacy incomes: $e');
    }
  }

  /// Synchronize transactions linked to a budget when its active status changes.
  ///
  /// - If [keepLinkedToBudget] is true, linked transactions keep `budgetId` and
  ///   their `isActive` follows [newBudgetIsActive].
  /// - If false, linked transactions are detached from the budget (`budgetId = null`)
  ///   and left active.
  Future<void> syncBudgetTransactionLinks({
    required String userId,
    required String budgetId,
    required bool newBudgetIsActive,
    required bool keepLinkedToBudget,
  }) async {
    try {
      final query = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('budgetId', isEqualTo: budgetId)
          .get();

      if (query.docs.isEmpty) {
        return;
      }

      const maxBatchSize = 400;
      var currentBatch = _firestore.batch();
      var count = 0;

      for (final doc in query.docs) {
        if (keepLinkedToBudget) {
          currentBatch.update(doc.reference, {'isActive': newBudgetIsActive});
        } else {
          currentBatch.update(doc.reference, {
            'budgetId': null,
            'isActive': true,
          });
        }

        count++;
        if (count >= maxBatchSize) {
          await currentBatch.commit();
          currentBatch = _firestore.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await currentBatch.commit();
      }
    } catch (e) {
      throw Exception('Failed to sync budget transactions: $e');
    }
  }

  // Private method to ensure user document exists
  Future<void> _ensureUserExists(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('⚠️ TRANSACTION SERVICE: User not found, creating user document');
        // Create basic user document if it doesn't exist
        await _firestore.collection('users').doc(userId).set({
          'id': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'lastLoginAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ TRANSACTION SERVICE: Error ensuring user exists: $e');
      // Don't throw here to prevent cascading failures
    }
  }
}
