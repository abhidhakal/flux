import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/recurring_transaction_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/recurring_transaction_service.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/budget_service.dart';
import '../../core/services/notification_trigger_service.dart';
import '../../core/services/enhanced_notification_service.dart';

// Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final String userId;

  const LoadTransactions(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddTransaction extends TransactionEvent {
  final Transaction transaction;
  final RecurringTransaction? recurringTransaction;

  const AddTransaction(this.transaction, {this.recurringTransaction});

  @override
  List<Object?> get props => [transaction, recurringTransaction];
}

class UpdateTransaction extends TransactionEvent {
  final Transaction transaction;

  const UpdateTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransaction extends TransactionEvent {
  final String transactionId;
  final String userId;

  const DeleteTransaction(this.transactionId, this.userId);

  @override
  List<Object?> get props => [transactionId, userId];
}

// States
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final String? message;

  const TransactionLoaded(this.transactions, {this.message});

  @override
  List<Object?> get props => [transactions, message];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionSuccess extends TransactionState {
  final String message;

  const TransactionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionService _transactionService;
  final RecurringTransactionService _recurringTransactionService;
  final BudgetService _budgetService;
  final NotificationTriggerService _notificationTriggerService;
  final EnhancedNotificationService? _enhancedNotificationService;

  TransactionBloc({
    required TransactionService transactionService,
    required RecurringTransactionService recurringTransactionService,
    required BudgetService budgetService,
    required NotificationTriggerService notificationTriggerService,
    EnhancedNotificationService? enhancedNotificationService,
  })  : _transactionService = transactionService,
        _recurringTransactionService = recurringTransactionService,
        _budgetService = budgetService,
        _notificationTriggerService = notificationTriggerService,
        _enhancedNotificationService = enhancedNotificationService,
        super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    try {
      await _recurringTransactionService.processDueTransactions(event.userId);
      final transactions =
          await _transactionService.getUserTransactions(event.userId);
      emit(TransactionLoaded(transactions));

      // Schedule/Check smart daily reminder
      _enhancedNotificationService?.scheduleSmartDailyLogReminder(event.userId);
      _enhancedNotificationService?.scheduleMorningGreeting(event.userId);
    } catch (e) {
      emit(TransactionError('Failed to load transactions: $e'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    try {
      await _transactionService.addTransaction(event.transaction);
      if (event.recurringTransaction != null) {
        await _recurringTransactionService
            .addRecurringTransaction(event.recurringTransaction!);
      }

      // Reload transactions
      final transactions = await _transactionService
          .getUserTransactions(event.transaction.userId);
      // Emit Loaded with Success Message
      emit(TransactionLoaded(transactions,
          message: 'Transaction added successfully!'));

      // Trigger notification checks
      _notificationTriggerService.monitorSpendingPatterns(
          event.transaction.userId, transactions);
      await _runPostMutationChecks(event.transaction.userId);
    } catch (e) {
      emit(TransactionError('Failed to add transaction: $e'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    try {
      await _transactionService.updateTransaction(event.transaction);

      // Reload transactions
      final transactions = await _transactionService
          .getUserTransactions(event.transaction.userId);
      emit(TransactionLoaded(transactions,
          message: 'Transaction updated successfully!'));

      // Trigger notification checks
      _notificationTriggerService.monitorSpendingPatterns(
          event.transaction.userId, transactions);
      await _runPostMutationChecks(event.transaction.userId);
    } catch (e) {
      emit(TransactionError('Failed to update transaction: $e'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    try {
      await _transactionService.deleteTransaction(event.transactionId);

      // Reload transactions after deletion using userId from event
      final transactions =
          await _transactionService.getUserTransactions(event.userId);
      emit(TransactionLoaded(transactions,
          message: 'Transaction deleted successfully!'));

      // Check budgets after deletion
      await _runPostMutationChecks(event.userId);
    } catch (e) {
      emit(TransactionError('Failed to delete transaction: $e'));
    }
  }

  // Shared tail for add/update/delete: refresh the daily-log reminder and
  // re-check budget thresholds now that a transaction changed spent amounts.
  Future<void> _runPostMutationChecks(String userId) async {
    _enhancedNotificationService?.updateDailyLogReminder(userId);
    // Best-effort: the transaction mutation already succeeded by the time
    // this runs, so a budget-monitoring failure here shouldn't flip an
    // already-emitted success state into an error.
    try {
      final budgets = await _budgetService.getUserBudgets(userId);
      _notificationTriggerService.monitorBudgetChanges(userId, budgets);
    } catch (e) {
      debugPrint('❌ TRANSACTION BLOC: Post-mutation budget check failed: $e');
    }
  }
}
