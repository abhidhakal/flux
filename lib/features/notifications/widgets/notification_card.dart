import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/notification_model.dart' as app_notification;
import '../../../shared/widgets/app_icon_badge.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationCard extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDismiss?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: const Icon(
          LucideIcons.trash2,
          color: Colors.white,
        ),
      ),
      child: Card(
        elevation: 0,
        color: AppTheme.cardSurface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: notification.isUnread
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildNotificationIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.typeDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPriorityChip(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTimeAgo(notification.age),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    if (notification.isActionable &&
                        notification.actionTitle != null)
                      TextButton(
                        onPressed: onTap,
                        child: Text(
                          notification.actionTitle!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case app_notification.NotificationType.budgetAlert:
        icon = LucideIcons.coins;
        color = AppColors.error;
        break;
      case app_notification.NotificationType.spendingReminder:
        icon = LucideIcons.scrollText;
        color = AppColors.warning;
        break;
      case app_notification.NotificationType.financialTip:
        icon = LucideIcons.lightbulb;
        color = AppColors.primary;
        break;
      case app_notification.NotificationType.goalMilestone:
        icon = LucideIcons.goal;
        color = AppColors.success;
        break;
      case app_notification.NotificationType.billReminder:
        icon = LucideIcons.clock;
        color = AppColors.warning;
        break;
      case app_notification.NotificationType.savingsReminder:
        icon = LucideIcons.piggyBank;
        color = AppColors.success;
        break;
      case app_notification.NotificationType.debtAlert:
        icon = LucideIcons.creditCard;
        color = AppColors.error;
        break;
      case app_notification.NotificationType.achievement:
        icon = LucideIcons.trophy;
        color = AppColors.accent;
        break;
    }

    return AppIconBadge(
      icon: icon,
      color: color,
      size: AppIconBadgeSize.medium,
    );
  }

  Widget _buildPriorityChip() {
    Color chipColor;
    IconData icon;

    switch (notification.priority) {
      case app_notification.NotificationPriority.low:
        chipColor = AppColors.success;
        icon = LucideIcons.info;
        break;
      case app_notification.NotificationPriority.medium:
        chipColor = AppColors.warning;
        icon = LucideIcons.zap;
        break;
      case app_notification.NotificationPriority.high:
        chipColor = AppColors.error;
        icon = LucideIcons.alertTriangle;
        break;
      case app_notification.NotificationPriority.urgent:
        chipColor = AppColors.error;
        icon = LucideIcons.alertCircle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            notification.priorityDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
