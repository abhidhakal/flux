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
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/premium_page_hero.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<app_notification.Notification> _lastLoadedNotifications = const [];
  bool _loadRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNotificationsIfNeeded(context);
    });
  }

  void _loadNotificationsIfNeeded(BuildContext context) {
    final notificationsState = context.read<NotificationsBloc>().state;
    final user = context.read<AuthBloc>().state;

    if (user is AuthAuthenticated &&
        !_loadRequested &&
        notificationsState is! NotificationsLoaded &&
        notificationsState is! NotificationsLoading) {
      _loadRequested = true;
      context.read<NotificationsBloc>().add(LoadNotifications(user.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageSurface(context),
      body: Column(
        children: [
          _buildNotificationsHero(),
          Expanded(
            child: BlocListener<AuthBloc, AuthState>(
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
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is NotificationsLoading &&
                        _lastLoadedNotifications.isNotEmpty) {
                      return _buildNotificationsList(_lastLoadedNotifications);
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
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsHero() {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final notifications = _notificationsFromState(state);
        final unreadCount = notifications.where((n) => n.isUnread).length;
        return PremiumPageHero(
          title: 'Notifications',
          showBackButton: true,
          subtitle: unreadCount == 0
              ? 'You’re all caught up'
              : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
          actions: [
            if (unreadCount > 0)
              PremiumPageHeroAction(
                icon: LucideIcons.checkCheck,
                tooltip: 'Mark all as read',
                onPressed: () {
                  final user = context.read<AuthBloc>().state;
                  if (user is AuthAuthenticated) {
                    context
                        .read<NotificationsBloc>()
                        .add(MarkAllAsRead(user.user.id));
                  }
                },
              ),
            if (unreadCount > 0) const SizedBox(width: 8),
            PremiumPageHeroAction(
              icon: LucideIcons.ellipsis,
              tooltip: 'Notification options',
              onPressed: () => _showNotificationOptions(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: LucideIcons.bell,
      iconColor: Theme.of(context).colorScheme.primary,
      title: 'All Caught Up!',
      titleFontSize: 24,
      subtitle:
          'You\'ll receive notifications when:\n• Your budget reaches 80%, 90%, or is exceeded\n• You hit goal milestones (25%, 50%, 90%)\n• Unusual spending is detected',
    );
  }

  Widget _buildErrorState(String message) {
    return EmptyStateView(
      icon: LucideIcons.alertCircle,
      iconColor: AppColors.error,
      title: 'Error Loading Notifications',
      titleFontSize: 20,
      subtitle: message,
      actionLabel: 'Retry',
      onAction: () {
        final user = context.read<AuthBloc>().state;
        if (user is AuthAuthenticated) {
          context
              .read<NotificationsBloc>()
              .add(LoadNotifications(user.user.id));
        }
      },
    );
  }

  Widget _buildNotificationsList(
      List<app_notification.Notification> notifications) {
    final unreadNotifications = notifications.where((n) => n.isUnread).toList();
    final readNotifications = notifications.where((n) => n.isRead).toList();

    // Flatten into one list of row descriptors so the whole thing can be
    // rendered lazily by ListView.builder instead of building every card
    // up front (this is what made the page slow with a large history).
    final rows = <Object>[
      if (unreadNotifications.isNotEmpty) ('New', unreadNotifications.length),
      ...unreadNotifications,
      if (readNotifications.isNotEmpty) ('Earlier', readNotifications.length),
      ...readNotifications,
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row is (String, int)) {
          return _buildSectionHeader(row.$1, row.$2);
        }
        final notification = row as app_notification.Notification;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: NotificationCard(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _handleDismissNotification(notification),
          ),
        );
      },
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
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
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.trash2, color: Colors.red),
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
