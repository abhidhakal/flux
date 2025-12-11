import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/income_model.dart';
import '../../core/services/income_service.dart';

// Events
abstract class IncomeEvent extends Equatable {
  const IncomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadIncome extends IncomeEvent {
  final String userId;

  const LoadIncome(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddIncome extends IncomeEvent {
  final Income income;

  const AddIncome(this.income);

  @override
  List<Object?> get props => [income];
}

class UpdateIncome extends IncomeEvent {
  final Income income;

  const UpdateIncome(this.income);

  @override
  List<Object?> get props => [income];
}

class DeleteIncome extends IncomeEvent {
  final String incomeId;
  final String userId;

  const DeleteIncome(this.incomeId, this.userId);

  @override
  List<Object?> get props => [incomeId, userId];
}

// States
abstract class IncomeState extends Equatable {
  const IncomeState();

  @override
  List<Object?> get props => [];
}

class IncomeInitial extends IncomeState {}

class IncomeLoading extends IncomeState {}

class IncomeLoaded extends IncomeState {
  final List<Income> incomes;

  const IncomeLoaded(this.incomes);

  @override
  List<Object?> get props => [incomes];
}

class IncomeError extends IncomeState {
  final String message;

  const IncomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class IncomeSuccess extends IncomeState {
  final String message;

  const IncomeSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  final IncomeService _incomeService;

  IncomeBloc({required IncomeService incomeService})
      : _incomeService = incomeService,
        super(IncomeInitial()) {
    on<LoadIncome>(_onLoadIncome);
    on<AddIncome>(_onAddIncome);
    on<UpdateIncome>(_onUpdateIncome);
    on<DeleteIncome>(_onDeleteIncome);
  }

  Future<void> _onLoadIncome(
    LoadIncome event,
    Emitter<IncomeState> emit,
  ) async {
    emit(IncomeLoading());
    try {
      final incomes = await _incomeService.getUserIncome(event.userId);
      emit(IncomeLoaded(incomes));
    } catch (e) {
      emit(IncomeError('Failed to load income: $e'));
    }
  }

  Future<void> _onAddIncome(
    AddIncome event,
    Emitter<IncomeState> emit,
  ) async {
    emit(IncomeLoading());
    try {
      await _incomeService.addIncome(event.income);
      emit(IncomeSuccess('Income added successfully!'));
      
      // Reload income
      final incomes = await _incomeService.getUserIncome(event.income.userId);
      emit(IncomeLoaded(incomes));
    } catch (e) {
      emit(IncomeError('Failed to add income: $e'));
    }
  }

  Future<void> _onUpdateIncome(
    UpdateIncome event,
    Emitter<IncomeState> emit,
  ) async {
    emit(IncomeLoading());
    try {
      await _incomeService.updateIncome(event.income);
      emit(IncomeSuccess('Income updated successfully!'));
      
      // Reload income
      final incomes = await _incomeService.getUserIncome(event.income.userId);
      emit(IncomeLoaded(incomes));
    } catch (e) {
      emit(IncomeError('Failed to update income: $e'));
    }
  }

  Future<void> _onDeleteIncome(
    DeleteIncome event,
    Emitter<IncomeState> emit,
  ) async {
    emit(IncomeLoading());
    try {
      await _incomeService.deleteIncome(event.incomeId);
      emit(IncomeSuccess('Income deleted successfully!'));
      
      // Reload income
      final incomes = await _incomeService.getUserIncome(event.userId);
      emit(IncomeLoaded(incomes));
    } catch (e) {
      emit(IncomeError('Failed to delete income: $e'));
    }
  }
}
