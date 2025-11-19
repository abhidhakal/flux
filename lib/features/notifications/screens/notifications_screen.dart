import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/notification_model.dart' as app_notification;
import '../../auth/auth_bloc.dart';
import '../notifications_bloc.dart';
import '../widgets/notification_card.dart';
import '../../../shared/widgets/app_snackbar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _loadNotificationsIfNeeded(BuildContext context) {
    final notificationsState = context.read<NotificationsBloc>().state;
    final user = context.read<AuthBloc>().state;
    
    print('🔔 NOTIFICATIONS SCREEN: _loadNotificationsIfNeeded called');
    print('🔔 NOTIFICATIONS SCREEN: Auth state: ${user.runtimeType}');
    print('🔔 NOTIFICATIONS SCREEN: Notifications state: ${notificationsState.runtimeType}');
    
    // Only load if we don't have notifications loaded and user is authenticated
    // Also ensure we're not already loading
    if (user is AuthAuthenticated && 
        notificationsState is! NotificationsLoaded && 
        notificationsState is! NotificationsLoading) {
      print('🔔 NOTIFICATIONS SCREEN: Loading notifications for user: ${user.user.id}');
      context.read<NotificationsBloc>().add(LoadNotifications(user.user.id));
      // Don't load cooldown check immediately to avoid state conflicts
      // Cooldown will be checked when needed
    } else {
      print('🔔 NOTIFICATIONS SCREEN: Not loading notifications - user: ${user.runtimeType}, notificationsState: ${notificationsState.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.notifications.isNotEmpty) {
                return PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onBackground),
                  onSelected: (value) {
                    final user = context.read<AuthBloc>().state;
                    if (user is AuthAuthenticated) {
                      if (value == 'mark_all_read') {
                        context.read<NotificationsBloc>().add(MarkAllAsRead(user.user.id));
                      } else if (value == 'generate_smart') {
                        _generateSmartNotifications(context, user.user.id);
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final notificationsState = context.read<NotificationsBloc>().state;
                    return [
                      const PopupMenuItem(
                        value: 'mark_all_read',
                        child: Row(
                          children: [
                            Icon(Icons.mark_email_read),
                            SizedBox(width: 8),
                            Text('Mark All as Read'),
                          ],
                        ),
                      ),
                      _buildSmartNotificationMenuItem(context, notificationsState),
                    ];
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          // Load notifications when authentication is complete
          if (authState is AuthAuthenticated) {
            _loadNotificationsIfNeeded(context);
          }
        },
        child: BlocListener<NotificationsBloc, NotificationsState>(
          listener: (context, state) {
            if (state is NotificationsSuccess) {
              AppSnackbar.showSuccess(context, message: state.message);
              
              // Refresh cooldown state after successful generation
              if (state.message.contains('Smart notifications generated')) {
                final user = context.read<AuthBloc>().state;
                if (user is AuthAuthenticated) {
                  context.read<NotificationsBloc>().add(CheckSmartNotificationCooldown(user.user.id));
                }
              }
            }
            
            if (state is NotificationsError) {
              AppSnackbar.showError(context, message: state.message);
            }
          },
          child: BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              // Handle initial state - show loading while we fetch notifications
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
                print('🔔 NOTIFICATIONS SCREEN: Found ${state.notifications.length} notifications in NotificationsLoaded state');
                if (state.notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildNotificationsList(state.notifications);
              }

              if (state is NotificationsError) {
                return _buildErrorState(state.message);
              }

              print('🔔 NOTIFICATIONS SCREEN: Current state is ${state.runtimeType}, showing empty state');
              return _buildEmptyState();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! We\'ll notify you about important financial updates.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final user = context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                _generateSmartNotifications(context, user.user.id);
              }
            },
            icon: const Icon(Icons.smart_toy),
            label: const Text('Generate Smart Alerts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
          ),
        ],
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
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final user = context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                context.read<NotificationsBloc>().add(LoadNotifications(user.user.id));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<app_notification.Notification> notifications) {
    final unreadNotifications = notifications.where((n) => n.isUnread).toList();
    final readNotifications = notifications.where((n) => n.isRead).toList();

    return Column(
      children: [
        if (unreadNotifications.isNotEmpty) ...[
          _buildSectionHeader('Unread', unreadNotifications.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: unreadNotifications.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationCard(
                    notification: unreadNotifications[index],
                    onTap: () => _handleNotificationTap(unreadNotifications[index]),
                    onDismiss: () => _handleDismissNotification(unreadNotifications[index]),
                  ),
                );
              },
            ),
          ),
        ],
        if (readNotifications.isNotEmpty) ...[
          _buildSectionHeader('Read', readNotifications.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: readNotifications.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationCard(
                    notification: readNotifications[index],
                    onTap: () => _handleNotificationTap(readNotifications[index]),
                    onDismiss: () => _handleDismissNotification(readNotifications[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(app_notification.Notification notification) {
    // Mark as read if unread
    if (notification.isUnread) {
      context.read<NotificationsBloc>().add(MarkAsRead(notification.id));
    }

    // Handle actionable notifications
    if (notification.isActionable && notification.actionRoute != null) {
      // Navigate to the appropriate screen
      switch (notification.actionRoute) {
        case '/budgets':
          // Navigate to budgets tab
          break;
        case '/transactions':
          // Navigate to transactions tab
          break;
        case '/goals':
          // Navigate to goals tab
          break;
        case '/analytics':
          // Navigate to analytics tab
          break;
      }
    }
  }

  void _handleDismissNotification(app_notification.Notification notification) {
    context.read<NotificationsBloc>().add(DismissNotification(notification.id));
  }

  PopupMenuEntry<String> _buildSmartNotificationMenuItem(BuildContext context, NotificationsState state) {
    if (state is SmartNotificationCooldownChecked) {
      if (state.canGenerate) {
        return const PopupMenuItem(
          value: 'generate_smart',
          child: Row(
            children: [
              Icon(Icons.smart_toy, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Generate Smart Alerts'),
            ],
          ),
        );
      } else {
        final minutes = state.timeUntilNextGeneration?.inMinutes ?? 0;
        return PopupMenuItem(
          value: 'generate_smart_disabled',
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Generate Smart Alerts',
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                  ),
                  Text(
                    'Available in ${minutes}m',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }
    
    // Default state - show as available
    return const PopupMenuItem(
      value: 'generate_smart',
      child: Row(
        children: [
          Icon(Icons.smart_toy, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Generate Smart Alerts'),
        ],
      ),
    );
  }

  void _generateSmartNotifications(BuildContext context, String userId) {
    // This would typically fetch data from other BLoCs
    // For now, we'll just trigger the generation
    context.read<NotificationsBloc>().add(
      GenerateSmartNotifications(
        userId: userId,
        budgets: [], // Would be fetched from BudgetBloc
        transactions: [], // Would be fetched from TransactionBloc
        goals: [], // Would be fetched from GoalsBloc
      ),
    );
  }
}
