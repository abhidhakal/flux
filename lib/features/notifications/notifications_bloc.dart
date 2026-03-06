import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/enhanced_notification_service.dart';

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

class RefreshNotifications extends NotificationsEvent {
  final String userId;

  const RefreshNotifications(this.userId);

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

class MarkAllAsRead extends NotificationsEvent {
  final String userId;

  const MarkAllAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ClearAllNotifications extends NotificationsEvent {
  final String userId;

  const ClearAllNotifications(this.userId);

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

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  @override
  List<Object?> get props => [notifications];
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

// BLoC
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final EnhancedNotificationService _notificationService;

  NotificationsBloc({required EnhancedNotificationService notificationService})
      : _notificationService = notificationService,
        super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<DismissNotification>(_onDismissNotification);
    on<DeleteNotification>(_onDeleteNotification);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<ClearAllNotifications>(_onClearAllNotifications);
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
      emit(NotificationsError('Failed to load notifications'));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final notifications = await _notificationService.getUserNotifications(event.userId);
      emit(NotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationsError('Failed to refresh notifications'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistic update — update in memory instantly, persist in background
    if (state is NotificationsLoaded) {
      final current = (state as NotificationsLoaded).notifications;
      final updated = current.map((n) => n.id == event.notificationId
          ? n.copyWith(status: NotificationStatus.read)
          : n).toList();
      emit(NotificationsLoaded(updated));
    }
    try {
      await _notificationService.markAsRead(event.notificationId);
    } catch (e) {
      emit(const NotificationsError('Failed to mark as read'));
    }
  }

  Future<void> _onDismissNotification(
    DismissNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistic update — remove from list instantly, persist in background
    if (state is NotificationsLoaded) {
      final current = (state as NotificationsLoaded).notifications;
      final updated = current.where((n) => n.id != event.notificationId).toList();
      emit(NotificationsLoaded(updated));
    }
    try {
      await _notificationService.dismissNotification(event.notificationId);
    } catch (e) {
      emit(const NotificationsError('Failed to dismiss notification'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistic update — remove from list instantly, persist in background
    if (state is NotificationsLoaded) {
      final current = (state as NotificationsLoaded).notifications;
      final updated = current.where((n) => n.id != event.notificationId).toList();
      emit(NotificationsLoaded(updated));
    }
    try {
      await _notificationService.deleteNotification(event.notificationId);
    } catch (e) {
      emit(const NotificationsError('Failed to delete notification'));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationService.markAllAsRead(event.userId);
      
      // Reload to show updated state
      final notifications = await _notificationService.getUserNotifications(event.userId);
      emit(NotificationsLoaded(notifications));
      emit(const NotificationsSuccess('All marked as read'));
    } catch (e) {
      emit(const NotificationsError('Failed to mark all as read'));
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationService.deleteAllNotifications(event.userId);
      
      emit(const NotificationsLoaded([]));
      emit(const NotificationsSuccess('All notifications cleared'));
    } catch (e) {
      emit(const NotificationsError('Failed to clear notifications'));
    }
  }
}
