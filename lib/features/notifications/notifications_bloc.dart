import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/budget_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/goal_model.dart';

// Events
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  final String userId;

  const LoadNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadUnreadNotifications extends NotificationsEvent {
  final String userId;

  const LoadUnreadNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MarkAsRead extends NotificationsEvent {
  final String notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class DismissNotification extends NotificationsEvent {
  final String notificationId;

  const DismissNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class DeleteNotification extends NotificationsEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class GenerateSmartNotifications extends NotificationsEvent {
  final String userId;
  final List<Budget> budgets;
  final List<Transaction> transactions;
  final List<Goal> goals;

  const GenerateSmartNotifications({
    required this.userId,
    required this.budgets,
    required this.transactions,
    required this.goals,
  });

  @override
  List<Object?> get props => [userId, budgets, transactions, goals];
}

class MarkAllAsRead extends NotificationsEvent {
  final String userId;

  const MarkAllAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CheckSmartNotificationCooldown extends NotificationsEvent {
  final String userId;

  const CheckSmartNotificationCooldown(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Notification> notifications;

  const NotificationsLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class UnreadNotificationsLoaded extends NotificationsState {
  final List<Notification> unreadNotifications;

  const UnreadNotificationsLoaded(this.unreadNotifications);

  @override
  List<Object?> get props => [unreadNotifications];
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationsSuccess extends NotificationsState {
  final String message;

  const NotificationsSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SmartNotificationCooldownChecked extends NotificationsState {
  final bool canGenerate;
  final Duration? timeUntilNextGeneration;

  const SmartNotificationCooldownChecked({
    required this.canGenerate,
    this.timeUntilNextGeneration,
  });

  @override
  List<Object?> get props => [canGenerate, timeUntilNextGeneration];
}

// BLoC
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationService _notificationService;

  NotificationsBloc({required NotificationService notificationService})
      : _notificationService = notificationService,
        super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUnreadNotifications>(_onLoadUnreadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<DismissNotification>(_onDismissNotification);
    on<DeleteNotification>(_onDeleteNotification);
    on<GenerateSmartNotifications>(_onGenerateSmartNotifications);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<CheckSmartNotificationCooldown>(_onCheckSmartNotificationCooldown);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    
    try {
      final notifications = await _notificationService.getUserNotifications(event.userId);
      emit(NotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onLoadUnreadNotifications(
    LoadUnreadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    
    try {
      final unreadNotifications = await _notificationService.getUnreadNotifications(event.userId);
      emit(UnreadNotificationsLoaded(unreadNotifications));
    } catch (e) {
      emit(NotificationsError('Failed to load unread notifications: $e'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationService.markAsRead(event.notificationId);
      emit(NotificationsSuccess('Notification marked as read'));
    } catch (e) {
      emit(NotificationsError('Failed to mark notification as read: $e'));
    }
  }

  Future<void> _onDismissNotification(
    DismissNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationService.dismissNotification(event.notificationId);
      emit(NotificationsSuccess('Notification dismissed'));
    } catch (e) {
      emit(NotificationsError('Failed to dismiss notification: $e'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationService.deleteNotification(event.notificationId);
      emit(NotificationsSuccess('Notification deleted'));
    } catch (e) {
      emit(NotificationsError('Failed to delete notification: $e'));
    }
  }

  Future<void> _onGenerateSmartNotifications(
    GenerateSmartNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    
    try {
      await _notificationService.generateSmartNotifications(
        event.userId,
        event.budgets,
        event.transactions,
        event.goals,
      );
      emit(NotificationsSuccess('Smart notifications generated successfully'));
    } catch (e) {
      emit(NotificationsError('Failed to generate smart notifications: $e'));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final unreadNotifications = await _notificationService.getUnreadNotifications(event.userId);
      
      for (final notification in unreadNotifications) {
        await _notificationService.markAsRead(notification.id);
      }
      
      emit(NotificationsSuccess('All notifications marked as read'));
    } catch (e) {
      emit(NotificationsError('Failed to mark all notifications as read: $e'));
    }
  }

  Future<void> _onCheckSmartNotificationCooldown(
    CheckSmartNotificationCooldown event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final canGenerate = await _notificationService.canGenerateSmartNotifications(event.userId);
      final timeUntilNext = await _notificationService.getTimeUntilNextGeneration(event.userId);
      
      emit(SmartNotificationCooldownChecked(
        canGenerate: canGenerate,
        timeUntilNextGeneration: timeUntilNext,
      ));
    } catch (e) {
      emit(NotificationsError('Failed to check smart notification cooldown: $e'));
    }
  }
}
