import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class TransactionService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Add transaction with automatic budget update
  Future<void> addTransaction(Transaction transaction) async {
    try {
      print('🔵 TRANSACTION SERVICE: Adding transaction');
      print('🔵 Transaction: ${transaction.title} - \$${transaction.amount}');
      print('🔵 Category: ${transaction.category}');
      print('🔵 Type: ${transaction.type.name}');

      // Generate ID if not provided
      final transactionId = transaction.id.isEmpty ? _uuid.v4() : transaction.id;
      final transactionToSave = transaction.copyWith(id: transactionId);

      // Use a batch to ensure atomic operations
      final batch = _firestore.batch();
      
      // Add transaction to Firestore
      final transactionRef = _firestore.collection('transactions').doc(transactionId);
      batch.set(transactionRef, transactionToSave.toJson());
      
      // If it's an expense, update the corresponding budget
      if (transactionToSave.isExpense) {
        await _updateBudgetForTransaction(transactionToSave, batch);
      }
      
      // Commit the batch
      await batch.commit();
      
      print('✅ TRANSACTION SERVICE: Transaction added successfully');
      print('✅ Budget updated (if expense)');
      
    } catch (e) {
      print('❌ TRANSACTION SERVICE: Error adding transaction: $e');
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Update transaction with budget recalculation
  Future<void> updateTransaction(Transaction newTransaction) async {
    try {
      print('🔵 TRANSACTION SERVICE: Updating transaction');
      print('🔵 Transaction ID: ${newTransaction.id}');
      
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
      final transactionRef = _firestore.collection('transactions').doc(newTransaction.id);
      batch.update(transactionRef, newTransaction.toJson());
      
      // Handle budget updates
      await _handleBudgetUpdateForTransactionChange(oldTransaction, newTransaction, batch);
      
      // Commit the batch
      await batch.commit();
      
      print('✅ TRANSACTION SERVICE: Transaction updated successfully');
      
    } catch (e) {
      print('❌ TRANSACTION SERVICE: Error updating transaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Delete transaction with budget adjustment
  Future<void> deleteTransaction(String transactionId) async {
    try {
      print('🔵 TRANSACTION SERVICE: Deleting transaction');
      print('🔵 Transaction ID: $transactionId');
      
      // Get the transaction before deleting
      final transactionDoc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();
      
      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }
      
      final transaction = Transaction.fromJson(transactionDoc.data()!);
      
      // Use a batch for atomic operations
      final batch = _firestore.batch();
      
      // Delete transaction
      final transactionRef = _firestore.collection('transactions').doc(transactionId);
      batch.delete(transactionRef);
      
      // If it was an expense, adjust the budget
      if (transaction.isExpense) {
        await _adjustBudgetForDeletedTransaction(transaction, batch);
      }
      
      // Commit the batch
      await batch.commit();
      
      print('✅ TRANSACTION SERVICE: Transaction deleted successfully');
      
    } catch (e) {
      print('❌ TRANSACTION SERVICE: Error deleting transaction: $e');
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Get user transactions
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      print('🔵 TRANSACTION SERVICE: Getting transactions for user: $userId');
      
      // Ensure user document exists
      await _ensureUserExists(userId);
      
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'expense')
          .orderBy('date', descending: true)
          .get();

      final transactions = querySnapshot.docs
          .map((doc) => Transaction.fromJson(doc.data()))
          .toList();
      
      print('✅ TRANSACTION SERVICE: Found ${transactions.length} transactions');
      return transactions;
      
    } catch (e) {
      print('❌ TRANSACTION SERVICE: Error getting transactions: $e');
      return [];
    }
  }

  // Check if user has transactions for today
  Future<bool> hasTransactionsToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      // Fetch recent transactions for user (filtering in Dart to avoid index issues)
      // We sort by date descending to get the latest ones effectively
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      // Check if any transaction is from today
      final hasToday = querySnapshot.docs.any((doc) {
        final data = doc.data();
        if (data['date'] == null) return false;
        
        final date = DateTime.parse(data['date']);
        return date.isAfter(startOfDay) && date.isBefore(endOfDay);
      });

      return hasToday;
    } catch (e) {
      print('❌ TRANSACTION SERVICE: Error checking today transactions: $e');
      return false;
    }
  }

  // Private method to update budget for new transaction
  Future<void> _updateBudgetForTransaction(Transaction transaction, firestore.WriteBatch batch) async {
    try {
      print('🔵 TRANSACTION SERVICE: Updating budget for transaction');
      
      // If no budgetId assigned, skip budget update
      if (transaction.budgetId == null || transaction.budgetId!.isEmpty) {
        print('⚠️ TRANSACTION SERVICE: No budget assigned to transaction');
        return;
      }
      
      print('🔵 Looking for budget with ID: ${transaction.budgetId}');
      
      // Find budget by ID
      final budgetDoc = await _firestore
          .collection('budgets')
          .doc(transaction.budgetId!)
          .get();

      if (!budgetDoc.exists) {
        print('⚠️ TRANSACTION SERVICE: Budget not found with ID: ${transaction.budgetId}');
        return;
      }

      final budget = Budget.fromJson(budgetDoc.data()!);
      
      // Verify budget belongs to user and is active
      if (budget.userId != transaction.userId || !budget.isActive) {
        print('⚠️ TRANSACTION SERVICE: Budget not active or belongs to different user');
        return;
      }
      
      print('✅ TRANSACTION SERVICE: Found budget: ${budget.name}');
      print('✅ Current spent: \$${budget.spent}');
      print('✅ Adding amount: \$${transaction.amount}');
      
      // Calculate new spent amount
      final newSpent = budget.spent + transaction.amount;
      
      // Update budget
      final budgetRef = _firestore.collection('budgets').doc(budget.id);
      batch.update(budgetRef, {'spent': newSpent});
      
      print('✅ TRANSACTION SERVICE: Budget updated - new spent: \$$newSpent');
      
    } catch (e) {
      print('❌ TRANSACTION SERVICE: Error updating budget: $e');
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
      print('🔵 TRANSACTION SERVICE: Handling budget update for transaction change');

      // 1. Identify affected budget IDs
      final String? oldBudgetId = oldTransaction.isExpense ? oldTransaction.budgetId : null;
      final String? newBudgetId = newTransaction.isExpense ? newTransaction.budgetId : null;

      // Case 1: No budgets involved
      if (oldBudgetId == null && newBudgetId == null) {
        print('⚠️ TRANSACTION SERVICE: No budgets affected');
        return;
      }

      // Case 2: Same budget - recalculate with net difference
      if (oldBudgetId == newBudgetId && oldBudgetId != null) {
        final budgetDoc = await _firestore.collection('budgets').doc(oldBudgetId).get();
        if (budgetDoc.exists) {
          final budget = Budget.fromJson(budgetDoc.data()!);
          if (budget.userId == newTransaction.userId && budget.isActive) {
            final netChange = newTransaction.amount - oldTransaction.amount;
            final newSpent = budget.spent + netChange;
            
            batch.update(budgetDoc.reference, {'spent': newSpent});
            print('✅ TRANSACTION SERVICE: Updated single budget ${budget.name} with net change: \$$netChange');
          }
        }
        return;
      }

      // Case 3: Different budgets or moving to/from no budget
      // Handle subtraction from old budget
      if (oldBudgetId != null) {
        final oldBudgetDoc = await _firestore.collection('budgets').doc(oldBudgetId).get();
        if (oldBudgetDoc.exists) {
          final oldBudget = Budget.fromJson(oldBudgetDoc.data()!);
          if (oldBudget.userId == oldTransaction.userId && oldBudget.isActive) {
            batch.update(oldBudgetDoc.reference, {'spent': oldBudget.spent - oldTransaction.amount});
            print('✅ TRANSACTION SERVICE: Subtracted amount from OLD budget: ${oldBudget.name}');
          }
        }
      }

      // Handle addition to new budget
      if (newBudgetId != null) {
        final newBudgetDoc = await _firestore.collection('budgets').doc(newBudgetId).get();
        if (newBudgetDoc.exists) {
          final newBudget = Budget.fromJson(newBudgetDoc.data()!);
          if (newBudget.userId == newTransaction.userId && newBudget.isActive) {
            batch.update(newBudgetDoc.reference, {'spent': newBudget.spent + newTransaction.amount});
            print('✅ TRANSACTION SERVICE: Added amount to NEW budget: ${newBudget.name}');
          }
        }
      }
      
    } catch (e) {
      print('❌ TRANSACTION SERVICE: Error handling budget update: $e');
      throw Exception('Failed to handle budget update: $e');
    }
  }

  // Private method to adjust budget for deleted transaction
  Future<void> _adjustBudgetForDeletedTransaction(Transaction transaction, firestore.WriteBatch batch) async {
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
        
        print('✅ TRANSACTION SERVICE: Adjusted budget for deleted transaction');
        }
      }
    } catch (e) {
      print('❌ TRANSACTION SERVICE: Error adjusting budget: $e');
    }
  }

  // Generate unique ID
  String generateId() {
    return _uuid.v4();
  }

  // Private method to ensure user document exists
  Future<void> _ensureUserExists(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        print('⚠️ TRANSACTION SERVICE: User not found, creating user document');
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
      print('❌ TRANSACTION SERVICE: Error ensuring user exists: $e');
      // Don't throw here to prevent cascading failures
    }
  }
}
