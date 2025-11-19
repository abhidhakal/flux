import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/transaction_service.dart';

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

  const AddTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
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

  const TransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
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

  TransactionBloc({required TransactionService transactionService})
      : _transactionService = transactionService,
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
      final transactions = await _transactionService.getUserTransactions(event.userId);
      emit(TransactionLoaded(transactions));
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
      emit(TransactionSuccess('Transaction added successfully!'));
      
      // Reload transactions
      final transactions = await _transactionService.getUserTransactions(event.transaction.userId);
      emit(TransactionLoaded(transactions));
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
      emit(TransactionSuccess('Transaction updated successfully!'));
      
      // Reload transactions
      final transactions = await _transactionService.getUserTransactions(event.transaction.userId);
      emit(TransactionLoaded(transactions));
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
      emit(TransactionSuccess('Transaction deleted successfully!'));
      
      // Reload transactions after deletion using userId from event
      final transactions = await _transactionService.getUserTransactions(event.userId);
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError('Failed to delete transaction: $e'));
    }
  }
}
