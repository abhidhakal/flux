import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/notification_model.dart' as app_notification;
import '../../auth/auth_bloc.dart';
import '../../goals/screens/goals_screen.dart';
import '../../main/navigation_cubit.dart';
import '../notifications_bloc.dart';
import '../widgets/notification_card.dart';
import '../../../shared/widgets/app_snackbar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<app_notification.Notification> _lastLoadedNotifications = const [];

  @override
  void initState() {
    super.initState();
  }

  void _loadNotificationsIfNeeded(BuildContext context) {
    final notificationsState = context.read<NotificationsBloc>().state;
    final user = context.read<AuthBloc>().state;

    if (user is AuthAuthenticated &&
        notificationsState is! NotificationsLoaded &&
        notificationsState is! NotificationsLoading) {
      context.read<NotificationsBloc>().add(LoadNotifications(user.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: theme.textTheme.displaySmall?.copyWith(
          fontSize: 24,
          letterSpacing: -1,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final notifications = _notificationsFromState(state);
              if (notifications.isNotEmpty) {
                final hasUnread = notifications.any((n) => n.isUnread);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasUnread)
                      IconButton(
                        icon: Icon(Icons.done_all,
                            color: Theme.of(context).colorScheme.onBackground),
                        tooltip: 'Mark All as Read',
                        onPressed: () {
                          final user = context.read<AuthBloc>().state;
                          if (user is AuthAuthenticated) {
                            context
                                .read<NotificationsBloc>()
                                .add(MarkAllAsRead(user.user.id));
                          }
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.more_vert,
                          color: Theme.of(context).colorScheme.onBackground),
                      onPressed: () => _showNotificationOptions(context),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is AuthAuthenticated) {
            _loadNotificationsIfNeeded(context);
          }
        },
        child: BlocListener<NotificationsBloc, NotificationsState>(
          listener: (context, state) {
            if (state is NotificationsSuccess) {
              AppSnackbar.showSuccess(context, message: state.message);
            }

            if (state is NotificationsError) {
              AppSnackbar.showError(context, message: state.message);
            }
          },
          child: BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsInitial) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadNotificationsIfNeeded(context);
                });
                return const Center(child: CircularProgressIndicator());
              }

              if (state is NotificationsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is NotificationsLoaded) {
                _lastLoadedNotifications = state.notifications;
                if (state.notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildNotificationsList(state.notifications);
              }

              if (state is NotificationsSuccess) {
                if (_lastLoadedNotifications.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildNotificationsList(_lastLoadedNotifications);
              }

              if (state is NotificationsError) {
                return _buildErrorState(state.message);
              }

              return _buildEmptyState();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'ll receive notifications when:\n• Your budget reaches 80%, 90%, or is exceeded\n• You hit goal milestones (25%, 50%, 90%)\n• Unusual spending is detected',
              style: TextStyle(
                fontSize: 14,
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final user = context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                context
                    .read<NotificationsBloc>()
                    .add(LoadNotifications(user.user.id));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      List<app_notification.Notification> notifications) {
    final unreadNotifications = notifications.where((n) => n.isUnread).toList();
    final readNotifications = notifications.where((n) => n.isRead).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (unreadNotifications.isNotEmpty) ...[
          _buildSectionHeader('New', unreadNotifications.length),
          ...unreadNotifications.map((notification) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: NotificationCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDismiss: () => _handleDismissNotification(notification),
                ),
              )),
        ],
        if (readNotifications.isNotEmpty) ...[
          _buildSectionHeader('Earlier', readNotifications.length),
          ...readNotifications.map((notification) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: NotificationCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDismiss: () => _handleDismissNotification(notification),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<app_notification.Notification> _notificationsFromState(
      NotificationsState state) {
    if (state is NotificationsLoaded) {
      return state.notifications;
    }
    return _lastLoadedNotifications;
  }

  void _handleNotificationTap(app_notification.Notification notification) {
    // Mark as read if unread
    if (notification.isUnread) {
      context.read<NotificationsBloc>().add(MarkAsRead(notification.id));
    }

    // Handle actionable notifications
    if (notification.isActionable && notification.actionRoute != null) {
      final navCubit = context.read<NavigationCubit>();

      switch (notification.actionRoute) {
        case '/budgets':
          navCubit.setTab(1);
          break;
        case '/transactions':
          navCubit.setTab(2);
          break;
        case '/goals':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GoalsScreen()),
          );
          return;
        case '/analytics':
          navCubit.setTab(3);
          break;
      }

      Navigator.pop(context);
    }
  }

  void _handleDismissNotification(app_notification.Notification notification) {
    context.read<NotificationsBloc>().add(DismissNotification(notification.id));
  }

  void _showNotificationOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              ),
              title: const Text(
                'Clear All Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              subtitle:
                  const Text('This will permanently delete all notifications'),
              onTap: () {
                Navigator.pop(context);
                _showClearAllDialog(this.context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final user = this.context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                this
                    .context
                    .read<NotificationsBloc>()
                    .add(ClearAllNotifications(user.user.id));
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
