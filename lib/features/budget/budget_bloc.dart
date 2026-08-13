import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/budget_model.dart';
import '../../core/services/budget_service.dart';
import '../../core/services/notification_trigger_service.dart';
import '../../core/services/premium_limits_service.dart';

// Events
abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgets extends BudgetEvent {
  final String userId;

  const LoadBudgets(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateBudget extends BudgetEvent {
  final Budget budget;

  const CreateBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class UpdateBudget extends BudgetEvent {
  final Budget budget;

  const UpdateBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class DeleteBudget extends BudgetEvent {
  final String budgetId;

  const DeleteBudget(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class ProcessBudgetRollovers extends BudgetEvent {
  final String userId;

  const ProcessBudgetRollovers(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RecalculateBudgetSpent extends BudgetEvent {
  final String userId;

  const RecalculateBudgetSpent(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final List<Budget> budgets;

  const BudgetLoaded(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}

class BudgetSuccess extends BudgetState {
  final String message;

  const BudgetSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetService _budgetService;
  final NotificationTriggerService _notificationTriggerService;
  final PremiumLimitsService _premiumLimitsService = PremiumLimitsService();

  BudgetBloc({
    required BudgetService budgetService,
    required NotificationTriggerService notificationTriggerService,
  })  : _budgetService = budgetService,
        _notificationTriggerService = notificationTriggerService,
        super(BudgetInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<CreateBudget>(_onCreateBudget);
    on<UpdateBudget>(_onUpdateBudget);
    on<DeleteBudget>(_onDeleteBudget);
    on<ProcessBudgetRollovers>(_onProcessBudgetRollovers);
    on<RecalculateBudgetSpent>(_onRecalculateBudgetSpent);
  }

  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());

    try {
      final budgets = await _budgetService.getUserBudgets(event.userId);
      emit(BudgetLoaded(budgets));
    } catch (e) {
      emit(BudgetError('Failed to load budgets: $e'));
    }
  }

  Future<void> _onCreateBudget(
    CreateBudget event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());

    try {
      final existingBudgets =
          await _budgetService.getUserBudgets(event.budget.userId);
      if (!_premiumLimitsService.canCreateBudget(existingBudgets)) {
        emit(const BudgetError(
            'Free accounts can have up to 3 active budgets. Upgrade to Flux Pro for unlimited budgets.'));
        return;
      }
      await _budgetService.createBudget(event.budget);

      // Reload budgets
      final budgets = await _budgetService.getUserBudgets(event.budget.userId);
      emit(BudgetLoaded(budgets));
      emit(BudgetSuccess('Budget created successfully!'));

      // Trigger notification check
      _notificationTriggerService.monitorBudgetChanges(
          event.budget.userId, budgets);
    } catch (e) {
      emit(BudgetError('Failed to create budget: $e'));
    }
  }

  Future<void> _onUpdateBudget(
    UpdateBudget event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());

    try {
      await _budgetService.updateBudget(event.budget);

      // Reload budgets
      final budgets = await _budgetService.getUserBudgets(event.budget.userId);
      emit(BudgetLoaded(budgets));
      emit(BudgetSuccess('Budget updated successfully!'));

      // Trigger notification check
      _notificationTriggerService.monitorBudgetChanges(
          event.budget.userId, budgets);
    } catch (e) {
      emit(BudgetError('Failed to update budget: $e'));
    }
  }

  Future<void> _onDeleteBudget(
    DeleteBudget event,
    Emitter<BudgetState> emit,
  ) async {
    final previousState = state;
    final userId =
        previousState is BudgetLoaded && previousState.budgets.isNotEmpty
            ? previousState.budgets.first.userId
            : null;
    emit(BudgetLoading());

    try {
      await _budgetService.deleteBudget(event.budgetId, userId: userId);
      emit(BudgetSuccess('Budget deleted successfully!'));

      if (userId != null) {
        final budgets = await _budgetService.getUserBudgets(userId);
        emit(BudgetLoaded(budgets));
      }
    } catch (e) {
      emit(BudgetError('Failed to delete budget: $e'));
    }
  }

  Future<void> _onProcessBudgetRollovers(
    ProcessBudgetRollovers event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());

    try {
      await _budgetService.processBudgetRollovers(event.userId);
      emit(BudgetSuccess('Budget rollovers processed successfully!'));

      // Reload budgets
      final budgets = await _budgetService.getUserBudgets(event.userId);
      emit(BudgetLoaded(budgets));
    } catch (e) {
      emit(BudgetError('Failed to process budget rollovers: $e'));
    }
  }

  Future<void> _onRecalculateBudgetSpent(
    RecalculateBudgetSpent event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());

    try {
      await _budgetService.recalculateBudgetSpent(event.userId);
      emit(BudgetSuccess('Budget spent amounts recalculated successfully!'));

      // Reload budgets
      final budgets = await _budgetService.getUserBudgets(event.userId);
      emit(BudgetLoaded(budgets));
    } catch (e) {
      emit(BudgetError('Failed to recalculate budget spent: $e'));
    }
  }
}
