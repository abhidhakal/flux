import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';
import '../constants/reminder_content.dart';
import 'currency_service.dart';
import 'enhanced_notification_service.dart';
import 'transaction_service.dart';

class NotificationTriggerService {
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();

  // Monitor budget changes and trigger alerts
  Future<void> monitorBudgetChanges(String userId, List<Budget> budgets) async {
    try {
      for (final budget in budgets) {
        if (!budget.isActive) continue;

        final percentageUsed = budget.progressPercentage;

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
      debugPrint('❌ NOTIFICATION TRIGGER: Error monitoring budget changes: $e');
    }
  }

  // Monitor goal progress and trigger milestone notifications
  Future<void> monitorGoalProgress(String userId, List<Goal> goals) async {
    try {
      for (final goal in goals) {
        if (goal.status != GoalStatus.active) continue;

        final progress = goal.progressPercentage;

        // Check for milestone achievements - Only 50% and 100%
        if (progress >= 50 && progress < 55) {
          await _triggerGoalMilestoneAlert(userId, goal, '50%');
        } else if (goal.isCompleted) {
          await _triggerGoalCompletedAlert(userId, goal);
        }
      }
    } catch (e) {
      debugPrint('❌ NOTIFICATION TRIGGER: Error monitoring goal progress: $e');
    }
  }

  // Monitor spending patterns and trigger alerts
  Future<void> monitorSpendingPatterns(
      String userId, List<Transaction> transactions) async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      final recentTransactions = transactions
          .where((t) => t.date.isAfter(lastWeek) && t.isExpense)
          .toList();

      if (recentTransactions.isNotEmpty) {
        final totalSpent =
            recentTransactions.fold(0.0, (sum, t) => sum + t.amount);

        // Calculate daily average to check for spikes
        final dailyAverage = totalSpent / 7;
        final todaySpent = transactions
            .where((t) =>
                t.date.day == now.day &&
                t.date.month == now.month &&
                t.date.year == now.year &&
                t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);

        if (todaySpent > dailyAverage * 2 && todaySpent > 50) {
          await _triggerDailySpendingAlert(userId, todaySpent, dailyAverage);
        }

        // Also check for high value transactions (Spikes)
        final averageSpent = totalSpent / recentTransactions.length;
        final highValueTransactions = recentTransactions
            .where((t) => t.amount > averageSpent * 3)
            .toList();

        if (highValueTransactions.isNotEmpty) {
          await _triggerSpendingPatternAlert(
              userId, highValueTransactions.length, totalSpent);
        }
      }
    } catch (e) {
      debugPrint(
          '❌ NOTIFICATION TRIGGER: Error monitoring spending patterns: $e');
    }
  }

  // Trigger budget warning alert (80-90%)
  Future<void> _triggerBudgetWarningAlert(
      String userId, Budget budget, double percentageUsed) async {
    try {
      // Check if we already sent this alert recently
      final alertKey = 'budget_warning_${budget.id}';
      if (await _hasRecentAlert(userId, alertKey)) return;
      if (_isQuietHours()) return;
      if (await _dailyCapReached(userId)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(alertKey),
          userId: userId,
          title: 'Budget Warning: ${budget.name}',
          message:
              'You\'ve used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.name} budget. Consider monitoring your spending.',
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
      await _incrementDailyCount(userId);
    } catch (e) {
      debugPrint('❌ NOTIFICATION TRIGGER: Error triggering budget warning: $e');
    }
  }

  // Trigger budget critical alert (90-100%)
  Future<void> _triggerBudgetCriticalAlert(
      String userId, Budget budget, double percentageUsed) async {
    try {
      final alertKey = 'budget_critical_${budget.id}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService
          .dismissNotification('budget_warning_${budget.id}');

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(alertKey),
          userId: userId,
          title: 'Budget Critical: ${budget.name}',
          message:
              'You\'ve used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.name} budget. Please review your spending immediately.',
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
      debugPrint(
          '❌ NOTIFICATION TRIGGER: Error triggering budget critical: $e');
    }
  }

  // Trigger budget exceeded alert (100%+)
  Future<void> _triggerBudgetExceededAlert(
      String userId, Budget budget, double percentageUsed) async {
    try {
      final alertKey = 'budget_exceeded_${budget.id}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService
          .dismissNotification('budget_warning_${budget.id}');
      await _notificationService
          .dismissNotification('budget_critical_${budget.id}');

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(alertKey),
          userId: userId,
          title: 'Budget Exceeded: ${budget.name}',
          message:
              'You\'ve exceeded your ${budget.name} budget by ${CurrencyService().formatAmount(budget.spent - budget.amount)}. Review your spending habits.',
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
      debugPrint(
          '❌ NOTIFICATION TRIGGER: Error triggering budget exceeded: $e');
    }
  }

  // Trigger goal milestone alert
  Future<void> _triggerGoalMilestoneAlert(
      String userId, Goal goal, String milestone) async {
    try {
      final alertKey = 'goal_milestone_${goal.id}_$milestone';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(alertKey),
          userId: userId,
          title: 'Goal Milestone: ${goal.name}',
          message:
              'Congratulations! You\'ve reached $milestone of your ${goal.name} goal. Keep up the great work!',
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
      debugPrint('❌ NOTIFICATION TRIGGER: Error triggering goal milestone: $e');
    }
  }

  // Trigger goal completed alert
  Future<void> _triggerGoalCompletedAlert(String userId, Goal goal) async {
    try {
      final alertKey = 'goal_completed_${goal.id}';
      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(alertKey),
          userId: userId,
          title: 'Goal Completed: ${goal.name}',
          message:
              '🎉 Congratulations! You\'ve successfully completed your ${goal.name} goal!',
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
      debugPrint('❌ NOTIFICATION TRIGGER: Error triggering goal completed: $e');
    }
  }

  // Trigger spending pattern alert
  Future<void> _triggerSpendingPatternAlert(
      String userId, int transactionCount, double totalSpent) async {
    try {
      final alertKey =
          'spending_pattern_${DateTime.now().millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000)}';
      if (await _hasRecentAlert(userId, alertKey)) return;
      if (_isQuietHours()) return;
      if (await _dailyCapReached(userId)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(alertKey),
          userId: userId,
          title: 'Unusual Spending Detected',
          message:
              'You\'ve made $transactionCount high-value transaction(s) this week totaling ${CurrencyService().formatAmount(totalSpent)}. Review your recent spending.',
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
      await _incrementDailyCount(userId);
    } catch (e) {
      debugPrint(
          '❌ NOTIFICATION TRIGGER: Error triggering spending pattern: $e');
    }
  }

  // Trigger daily spending alert
  Future<void> _triggerDailySpendingAlert(
      String userId, double todaySpent, double dailyAverage) async {
    try {
      final alertKey =
          'daily_spending_${DateTime.now().millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000)}';
      if (await _hasRecentAlert(userId, alertKey)) return;
      if (_isQuietHours()) return;
      if (await _dailyCapReached(userId)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: _generateId(alertKey),
          userId: userId,
          title: 'High Daily Spending',
          message:
              'You\'ve spent ${CurrencyService().formatAmount(todaySpent)} today, which is ${((todaySpent / dailyAverage) * 100).toStringAsFixed(0)}% above your daily average.',
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
      await _incrementDailyCount(userId);
    } catch (e) {
      debugPrint('❌ NOTIFICATION TRIGGER: Error triggering daily spending: $e');
    }
  }

  // Non-urgent alerts stay quiet 10pm-8am; critical/exceeded still get through.
  bool _isQuietHours() {
    final hour = DateTime.now().hour;
    return hour >= 22 || hour < 8;
  }

  static const int _maxNonUrgentAlertsPerDay = 5;

  // Server-side mirror of alert-sent state, so cooldown/cap survive a
  // reinstall or a second device instead of resetting on local prefs alone.
  CollectionReference<Map<String, dynamic>> get _stateCol =>
      FirebaseFirestore.instance.collection('notification_alert_state');

  String _todayStr() {
    final today = DateTime.now();
    return '${today.year}_${today.month}_${today.day}';
  }

  String _dailyCountKey(String userId) => 'alert_count_${userId}_${_todayStr()}';

  // Caps non-urgent alerts (warning/spending pattern/daily spending) per day.
  // Critical/exceeded/goal alerts bypass this - they're rare and important.
  Future<bool> _dailyCapReached(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _dailyCountKey(userId);
      int count = prefs.getInt(key) ?? 0;

      if (count == 0) {
        // No local record for today - could be a fresh install/new device.
        final doc = await _stateCol.doc(userId).get();
        final data = doc.data();
        if (data != null && data['dailyCountDate'] == _todayStr()) {
          count = (data['dailyCount'] as num?)?.toInt() ?? 0;
          await prefs.setInt(key, count);
        }
      }

      return count >= _maxNonUrgentAlertsPerDay;
    } catch (e) {
      debugPrint('❌ NOTIFICATION TRIGGER: Error checking daily cap: $e');
      return false;
    }
  }

  Future<void> _incrementDailyCount(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _dailyCountKey(userId);
      final newCount = (prefs.getInt(key) ?? 0) + 1;
      await prefs.setInt(key, newCount);
      await _stateCol.doc(userId).set(
        {'dailyCount': newCount, 'dailyCountDate': _todayStr()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('❌ NOTIFICATION TRIGGER: Error incrementing daily count: $e');
    }
  }

  // Check if we've sent a recent alert. Local prefs is the fast path; a
  // fresh install/new device falls through to the Firestore mirror so the
  // same alert doesn't refire just because local state is empty.
  Future<bool> _hasRecentAlert(String userId, String alertKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localKey = 'alert_${userId}_$alertKey';
      final lastSentStr = prefs.getString(localKey);

      if (lastSentStr != null) {
        final hoursSinceSent =
            DateTime.now().difference(DateTime.parse(lastSentStr)).inHours;
        if (hoursSinceSent < 24) return true;
      }

      final doc = await _stateCol.doc(userId).get();
      final remoteStr = doc.data()?[alertKey] as String?;
      if (remoteStr != null) {
        final hoursSinceSent =
            DateTime.now().difference(DateTime.parse(remoteStr)).inHours;
        if (hoursSinceSent < 24) {
          await prefs.setString(localKey, remoteStr);
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ NOTIFICATION TRIGGER: Error checking recent alert: $e');
      return false;
    }
  }

  // Record that an alert was sent, locally and in the Firestore mirror.
  Future<void> _recordAlertSent(String userId, String alertKey) async {
    try {
      final now = DateTime.now().toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alert_${userId}_$alertKey', now);
      await _stateCol.doc(userId).set({alertKey: now}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ NOTIFICATION TRIGGER: Error recording alert sent: $e');
    }
  }

  // Generate deterministic notification ID from alert key so repeated triggers
  // upsert the same Firestore document instead of creating duplicates.
  String _generateId(String alertKey) {
    return alertKey;
  }

  // Trigger a morning greeting notification
  Future<void> triggerMorningGreeting(String userId) async {
    try {
      final today = DateTime.now();
      final alertKey =
          'morning_greeting_${today.year}_${today.month}_${today.day}';

      if (await _hasRecentAlert(userId, alertKey)) return;

      await _notificationService.createNotificationWithPush(
        Notification(
          id: alertKey,
          userId: userId,
          title: 'Good Morning!',
          message: 'Start your day right by checking your financial progress.',
          type: NotificationType.financialTip,
          priority: NotificationPriority.low,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          isActionable: true,
          actionTitle: 'Launch Flux',
          actionRoute: '/',
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      debugPrint(
          '❌ NOTIFICATION TRIGGER: Error triggering morning greeting: $e');
    }
  }

  // Trigger a daily reminder notification
  Future<void> triggerDailyReminder(String userId, String type) async {
    try {
      final today = DateTime.now();
      final alertKey =
          'daily_reminder_${type}_${today.year}_${today.month}_${today.day}';

      if (await _hasRecentAlert(userId, alertKey)) return;

      // Don't nag about logging expenses if the user already has today.
      if (type == 'expense_log' &&
          await TransactionService().hasTransactionsToday(userId)) {
        return;
      }

      final content = ReminderContent.forType(type);

      await _notificationService.createNotificationWithPush(
        Notification(
          id: alertKey,
          userId: userId,
          title: content.title,
          message: content.body,
          type: NotificationType.spendingReminder,
          priority: NotificationPriority.medium,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          isActionable: true,
          actionTitle: 'Check Now',
          actionRoute: content.route,
        ),
      );

      await _recordAlertSent(userId, alertKey);
    } catch (e) {
      debugPrint('❌ NOTIFICATION TRIGGER: Error triggering daily reminder: $e');
    }
  }
}
