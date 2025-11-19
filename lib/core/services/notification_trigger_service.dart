import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';
import 'enhanced_notification_service.dart';

class NotificationTriggerService {
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  // Monitor budget changes and trigger alerts
  Future<void> monitorBudgetChanges(String userId, List<Budget> budgets) async {
    try {
      for (final budget in budgets) {
        if (!budget.isActive) continue;

        final percentageUsed = (budget.spent / budget.amount) * 100;
        
        // Check for budget alerts
        if (percentageUsed >= 80 && percentageUsed < 90) {
          await _triggerBudgetWarningAlert(userId, budget, percentageUsed);
        } else if (percentageUsed >= 90 && percentageUsed < 100) {
          await _triggerBudgetCriticalAlert(userId, budget, percentageUsed);
        } else if (percentageUsed >= 100) {
          await _triggerBudgetExceededAlert(userId, budget, percentageUsed);
        }
      }
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error monitoring budget changes: $e');
    }
  }

  // Monitor goal progress and trigger milestone notifications
  Future<void> monitorGoalProgress(String userId, List<Goal> goals) async {
    try {
      for (final goal in goals) {
        if (goal.status != GoalStatus.active) continue;

        final progress = goal.progressPercentage;
        
        // Check for milestone achievements
        if (progress >= 25 && progress < 30) {
          await _triggerGoalMilestoneAlert(userId, goal, '25%');
        } else if (progress >= 50 && progress < 55) {
          await _triggerGoalMilestoneAlert(userId, goal, '50%');
        } else if (progress >= 75 && progress < 80) {
          await _triggerGoalMilestoneAlert(userId, goal, '75%');
        } else if (progress >= 90 && progress < 95) {
          await _triggerGoalMilestoneAlert(userId, goal, '90%');
        } else if (goal.isCompleted) {
          await _triggerGoalCompletedAlert(userId, goal);
        }
      }
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error monitoring goal progress: $e');
    }
  }

  // Monitor spending patterns and trigger alerts
  Future<void> monitorSpendingPatterns(String userId, List<Transaction> transactions) async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      
      final recentTransactions = transactions
          .where((t) => t.date.isAfter(lastWeek) && t.isExpense)
          .toList();

      if (recentTransactions.isNotEmpty) {
        final totalSpent = recentTransactions.fold(0.0, (sum, t) => sum + t.amount);
        final averageSpent = totalSpent / recentTransactions.length;
        
        // Check for unusual spending patterns
        final highValueTransactions = recentTransactions
            .where((t) => t.amount > averageSpent * 2)
            .toList();

        if (highValueTransactions.isNotEmpty) {
          await _triggerSpendingPatternAlert(userId, highValueTransactions.length, totalSpent);
        }

        // Check for daily spending spikes
        final today = DateTime(now.year, now.month, now.day);
        final todayTransactions = recentTransactions
            .where((t) => t.date.isAfter(today))
            .toList();

        if (todayTransactions.isNotEmpty) {
          final todaySpent = todayTransactions.fold(0.0, (sum, t) => sum + t.amount);
          final dailyAverage = totalSpent / 7;
          
          if (todaySpent > dailyAverage * 1.5) {
            await _triggerDailySpendingAlert(userId, todaySpent, dailyAverage);
          }
        }
      }
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error monitoring spending patterns: $e');
    }
  }

  // Trigger budget warning alert (80-90%)
  Future<void> _triggerBudgetWarningAlert(String userId, Budget budget, double percentageUsed) async {
    try {
      // Check if we already sent this alert recently
      final alertKey = 'budget_warning_${budget.id}_${percentageUsed.round()}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(),
          userId: userId,
          title: 'Budget Warning: ${budget.name}',
          message: 'You\'ve used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.name} budget. Consider monitoring your spending.',
          type: NotificationType.budgetAlert,
          priority: NotificationPriority.medium,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'budgetId': budget.id,
            'budgetName': budget.name,
            'percentageUsed': percentageUsed,
            'remaining': budget.remaining,
            'alertType': 'warning',
          },
          isActionable: true,
          actionTitle: 'View Budget',
          actionRoute: '/budgets',
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error triggering budget warning: $e');
    }
  }

  // Trigger budget critical alert (90-100%)
  Future<void> _triggerBudgetCriticalAlert(String userId, Budget budget, double percentageUsed) async {
    try {
      final alertKey = 'budget_critical_${budget.id}_${percentageUsed.round()}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(),
          userId: userId,
          title: 'Budget Critical: ${budget.name}',
          message: 'You\'ve used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.name} budget. Please review your spending immediately.',
          type: NotificationType.budgetAlert,
          priority: NotificationPriority.high,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'budgetId': budget.id,
            'budgetName': budget.name,
            'percentageUsed': percentageUsed,
            'remaining': budget.remaining,
            'alertType': 'critical',
          },
          isActionable: true,
          actionTitle: 'Review Budget',
          actionRoute: '/budgets',
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error triggering budget critical: $e');
    }
  }

  // Trigger budget exceeded alert (100%+)
  Future<void> _triggerBudgetExceededAlert(String userId, Budget budget, double percentageUsed) async {
    try {
      final alertKey = 'budget_exceeded_${budget.id}_${percentageUsed.round()}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(),
          userId: userId,
          title: 'Budget Exceeded: ${budget.name}',
          message: 'You\'ve exceeded your ${budget.name} budget by \$${(budget.spent - budget.amount).toStringAsFixed(2)}. Review your spending habits.',
          type: NotificationType.budgetAlert,
          priority: NotificationPriority.urgent,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'budgetId': budget.id,
            'budgetName': budget.name,
            'exceededAmount': budget.spent - budget.amount,
            'alertType': 'exceeded',
          },
          isActionable: true,
          actionTitle: 'Review Budget',
          actionRoute: '/budgets',
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error triggering budget exceeded: $e');
    }
  }

  // Trigger goal milestone alert
  Future<void> _triggerGoalMilestoneAlert(String userId, Goal goal, String milestone) async {
    try {
      final alertKey = 'goal_milestone_${goal.id}_$milestone';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(),
          userId: userId,
          title: 'Goal Milestone: ${goal.name}',
          message: 'Congratulations! You\'ve reached $milestone of your ${goal.name} goal. Keep up the great work!',
          type: NotificationType.goalMilestone,
          priority: NotificationPriority.high,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'goalId': goal.id,
            'goalName': goal.name,
            'progress': goal.progressPercentage,
            'milestone': milestone,
          },
          isActionable: true,
          actionTitle: 'View Goal',
          actionRoute: '/goals',
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error triggering goal milestone: $e');
    }
  }

  // Trigger goal completed alert
  Future<void> _triggerGoalCompletedAlert(String userId, Goal goal) async {
    try {
      final alertKey = 'goal_completed_${goal.id}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(),
          userId: userId,
          title: 'Goal Completed: ${goal.name}',
          message: '🎉 Congratulations! You\'ve successfully completed your ${goal.name} goal!',
          type: NotificationType.achievement,
          priority: NotificationPriority.high,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'goalId': goal.id,
            'goalName': goal.name,
            'completedAt': goal.completedAt?.toIso8601String(),
          },
          isActionable: true,
          actionTitle: 'View Achievement',
          actionRoute: '/goals',
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error triggering goal completed: $e');
    }
  }

  // Trigger spending pattern alert
  Future<void> _triggerSpendingPatternAlert(String userId, int transactionCount, double totalSpent) async {
    try {
      final alertKey = 'spending_pattern_${DateTime.now().millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000)}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(),
          userId: userId,
          title: 'Unusual Spending Detected',
          message: 'You\'ve made $transactionCount high-value transaction(s) this week totaling \$${totalSpent.toStringAsFixed(2)}. Review your recent spending.',
          type: NotificationType.spendingReminder,
          priority: NotificationPriority.medium,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'transactionCount': transactionCount,
            'totalSpent': totalSpent,
            'alertType': 'spending_pattern',
          },
          isActionable: true,
          actionTitle: 'View Transactions',
          actionRoute: '/transactions',
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error triggering spending pattern: $e');
    }
  }

  // Trigger daily spending alert
  Future<void> _triggerDailySpendingAlert(String userId, double todaySpent, double dailyAverage) async {
    try {
      final alertKey = 'daily_spending_${DateTime.now().millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000)}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(),
          userId: userId,
          title: 'High Daily Spending',
          message: 'You\'ve spent \$${todaySpent.toStringAsFixed(2)} today, which is ${((todaySpent / dailyAverage) * 100).toStringAsFixed(0)}% above your daily average.',
          type: NotificationType.spendingReminder,
          priority: NotificationPriority.medium,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'todaySpent': todaySpent,
            'dailyAverage': dailyAverage,
            'alertType': 'daily_spending',
          },
          isActionable: true,
          actionTitle: 'View Today\'s Spending',
          actionRoute: '/transactions',
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error triggering daily spending: $e');
    }
  }

  // Check if we've sent a recent alert
  Future<bool> _hasRecentAlert(String userId, String alertKey) async {
    try {
      final alertDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recent_alerts')
          .doc(alertKey)
          .get();

      if (alertDoc.exists) {
        final data = alertDoc.data()!;
        final sentAt = DateTime.parse(data['sentAt']);
        final hoursSinceSent = DateTime.now().difference(sentAt).inHours;
        
        // Don't send the same alert within 24 hours
        return hoursSinceSent < 24;
      }
      return false;
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error checking recent alert: $e');
      return false;
    }
  }

  // Record that an alert was sent
  Future<void> _recordAlertSent(String userId, String alertKey) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recent_alerts')
          .doc(alertKey)
          .set({
        'sentAt': DateTime.now().toIso8601String(),
        'alertKey': alertKey,
      });
    } catch (e) {
      print('❌ NOTIFICATION TRIGGER: Error recording alert: $e');
    }
  }

  // Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
