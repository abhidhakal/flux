import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/goal_model.dart';
import '../../core/services/goal_service.dart';
import '../../core/services/notification_trigger_service.dart';
import '../../core/services/premium_limits_service.dart';

// Events
abstract class GoalsEvent extends Equatable {
  const GoalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadGoals extends GoalsEvent {
  final String userId;

  const LoadGoals(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateGoal extends GoalsEvent {
  final Goal goal;

  const CreateGoal(this.goal);

  @override
  List<Object?> get props => [goal];
}

class UpdateGoal extends GoalsEvent {
  final Goal goal;

  const UpdateGoal(this.goal);

  @override
  List<Object?> get props => [goal];
}

class DeleteGoal extends GoalsEvent {
  final String goalId;
  final String userId;

  const DeleteGoal(this.goalId, this.userId);

  @override
  List<Object?> get props => [goalId, userId];
}

class UpdateGoalProgress extends GoalsEvent {
  final String goalId;
  final double amount;
  final String userId;

  const UpdateGoalProgress({
    required this.goalId,
    required this.amount,
    required this.userId,
  });

  @override
  List<Object?> get props => [goalId, amount, userId];
}

class GetGoalStatistics extends GoalsEvent {
  final String userId;

  const GetGoalStatistics(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GenerateGoalRecommendations extends GoalsEvent {
  final String userId;
  final double monthlyIncome;

  const GenerateGoalRecommendations({
    required this.userId,
    required this.monthlyIncome,
  });

  @override
  List<Object?> get props => [userId, monthlyIncome];
}

// States
abstract class GoalsState extends Equatable {
  const GoalsState();

  @override
  List<Object?> get props => [];
}

class GoalsInitial extends GoalsState {}

class GoalsLoading extends GoalsState {}

class GoalsLoaded extends GoalsState {
  final List<Goal> goals;

  const GoalsLoaded(this.goals);

  @override
  List<Object?> get props => [goals];
}

class GoalStatisticsLoaded extends GoalsState {
  final Map<String, dynamic> statistics;

  const GoalStatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

class GoalRecommendationsLoaded extends GoalsState {
  final List<Map<String, dynamic>> recommendations;

  const GoalRecommendationsLoaded(this.recommendations);

  @override
  List<Object?> get props => [recommendations];
}

class GoalsError extends GoalsState {
  final String message;

  const GoalsError(this.message);

  @override
  List<Object?> get props => [message];
}

class GoalsSuccess extends GoalsState {
  final String message;

  const GoalsSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  final GoalService _goalService;
  final NotificationTriggerService _notificationTriggerService;
  final PremiumLimitsService _premiumLimitsService = PremiumLimitsService();

  GoalsBloc({
    required GoalService goalService,
    required NotificationTriggerService notificationTriggerService,
  })  : _goalService = goalService,
        _notificationTriggerService = notificationTriggerService,
        super(GoalsInitial()) {
    on<LoadGoals>(_onLoadGoals);
    on<CreateGoal>(_onCreateGoal);
    on<UpdateGoal>(_onUpdateGoal);
    on<DeleteGoal>(_onDeleteGoal);
    on<UpdateGoalProgress>(_onUpdateGoalProgress);
    on<GetGoalStatistics>(_onGetGoalStatistics);
    on<GenerateGoalRecommendations>(_onGenerateGoalRecommendations);
  }

  Future<void> _onLoadGoals(
    LoadGoals event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    try {
      final goals = await _goalService.getUserGoals(event.userId);
      emit(GoalsLoaded(goals));
    } catch (e) {
      emit(GoalsError('Failed to load goals: $e'));
    }
  }

  Future<void> _onCreateGoal(
    CreateGoal event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    try {
      final existingGoals = await _goalService.getUserGoals(event.goal.userId);
      if (!_premiumLimitsService.canCreateGoal(existingGoals)) {
        emit(const GoalsError(
            'Free accounts can have up to 2 active goals. Upgrade to Flux Pro for unlimited goals.'));
        return;
      }
      await _goalService.createGoal(event.goal);

      // Reload goals immediately after creation
      final goals = await _goalService.getUserGoals(event.goal.userId);
      emit(GoalsLoaded(goals));
      emit(const GoalsSuccess('Goal created successfully!'));
    } catch (e) {
      emit(GoalsError('Failed to create goal: $e'));
    }
  }

  Future<void> _onUpdateGoal(
    UpdateGoal event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    try {
      await _goalService.updateGoal(event.goal);

      // Reload goals immediately after update
      final goals = await _goalService.getUserGoals(event.goal.userId);
      emit(GoalsLoaded(goals));

      // Trigger notification check
      _notificationTriggerService.monitorGoalProgress(event.goal.userId, goals);
    } catch (e) {
      emit(GoalsError('Failed to update goal: $e'));
    }
  }

  Future<void> _onDeleteGoal(
    DeleteGoal event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    try {
      await _goalService.deleteGoal(event.goalId, userId: event.userId);
      // Reload goals for provided user
      final goals = await _goalService.getUserGoals(event.userId);
      emit(GoalsLoaded(goals));
      emit(const GoalsSuccess('Goal deleted successfully!'));
    } catch (e) {
      emit(GoalsError('Failed to delete goal: $e'));
    }
  }

  Future<void> _onUpdateGoalProgress(
    UpdateGoalProgress event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    try {
      await _goalService.updateGoalProgress(event.goalId, event.amount);

      // Reload goals
      final goals = await _goalService.getUserGoals(event.userId);
      emit(GoalsLoaded(goals));
      emit(const GoalsSuccess('Progress added successfully'));

      // Trigger notification check
      _notificationTriggerService.monitorGoalProgress(event.userId, goals);
    } catch (e) {
      emit(GoalsError('Failed to update goal progress: $e'));
    }
  }

  Future<void> _onGetGoalStatistics(
    GetGoalStatistics event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    try {
      final statistics = await _goalService.getGoalStatistics(event.userId);
      emit(GoalStatisticsLoaded(statistics));
    } catch (e) {
      emit(GoalsError('Failed to get goal statistics: $e'));
    }
  }

  Future<void> _onGenerateGoalRecommendations(
    GenerateGoalRecommendations event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    try {
      final existingGoals = await _goalService.getUserGoals(event.userId);
      final recommendations = await _goalService.generateGoalRecommendations(
        event.userId,
        event.monthlyIncome,
        existingGoals,
      );
      emit(GoalRecommendationsLoaded(recommendations));
    } catch (e) {
      emit(GoalsError('Failed to generate goal recommendations: $e'));
    }
  }
}
