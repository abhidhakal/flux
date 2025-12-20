import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';
import 'transaction_service.dart';

class EnhancedNotificationService {
  final NotificationService _notificationService = NotificationService();
  final PushNotificationService _pushService = PushNotificationService();
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Initialize the enhanced notification service
  Future<void> initialize() async {
    await _pushService.initialize();
    await _requestPermissions();
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    return await _pushService.requestPermissions();
  }

  // Request notification permissions (public method)
  Future<bool> requestPermissions() async {
    return await _pushService.requestPermissions();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _pushService.areNotificationsEnabled();
  }

  // Create notification with push notification
  Future<void> createNotificationWithPush(Notification notification) async {
    try {
      // Create in Firestore
      await _notificationService.createNotification(notification);
      
      // Send push notification if enabled
      if (await areNotificationsEnabled()) {
        await _pushService.showNotification(
          id: notification.id.hashCode,
          title: notification.title,
          body: notification.message,
          priority: notification.priority,
          payload: 'notification:${notification.id}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create notification with push: $e');
    }
  }

  // Generate smart notifications with push notifications
  Future<void> generateSmartNotificationsWithPush(
    String userId,
    List<Budget> budgets,
    List<Transaction> transactions,
    List<Goal> goals,
  ) async {
    try {
      // Generate Firestore notifications
      await _notificationService.generateSmartNotifications(
        userId,
        budgets,
        transactions,
        goals,
      );

      // Send push notifications for critical alerts
      await _generatePushNotifications(userId, budgets, transactions, goals);
      
    } catch (e) {
      throw Exception('Failed to generate smart notifications with push: $e');
    }
  }

  // Generate push notifications for critical alerts
  Future<void> _generatePushNotifications(
    String userId,
    List<Budget> budgets,
    List<Transaction> transactions,
    List<Goal> goals,
  ) async {
    if (!await areNotificationsEnabled()) return;

    // Budget alerts
    await _generateBudgetPushAlerts(budgets);
    
    // Goal milestones
    await _generateGoalPushMilestones(goals);
    
    // Spending alerts
    await _generateSpendingPushAlerts(transactions);
  }

  // Generate budget push alerts
  Future<void> _generateBudgetPushAlerts(List<Budget> budgets) async {
    for (final budget in budgets) {
      if (!budget.isActive) continue;

      final percentageUsed = (budget.spent / budget.amount) * 100;
      
      if (percentageUsed >= 90) {
        await _pushService.showBudgetAlert(
          budgetName: budget.name,
          percentageUsed: percentageUsed,
          remaining: budget.remaining,
        );
      }
    }
  }

  // Generate goal push milestones
  Future<void> _generateGoalPushMilestones(List<Goal> goals) async {
    for (final goal in goals) {
      if (goal.status != GoalStatus.active) continue;

      final progress = goal.progressPercentage;
      
      // Check for milestone achievements
      if (progress >= 25 && progress < 30) {
        await _pushService.showGoalMilestone(
          goalName: goal.name,
          progress: progress,
          milestone: '25%',
        );
      } else if (progress >= 50 && progress < 55) {
        await _pushService.showGoalMilestone(
          goalName: goal.name,
          progress: progress,
          milestone: '50%',
        );
      } else if (progress >= 90 && progress < 95) {
        await _pushService.showGoalMilestone(
          goalName: goal.name,
          progress: progress,
          milestone: '90%',
        );
      }
    }
  }

  // Generate spending push alerts
  Future<void> _generateSpendingPushAlerts(List<Transaction> transactions) async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(lastWeek) && t.isExpense)
        .toList();

    if (recentTransactions.isNotEmpty) {
      final totalSpent = recentTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final averageSpent = totalSpent / recentTransactions.length;
      
      final highValueTransactions = recentTransactions
          .where((t) => t.amount > averageSpent * 2)
          .toList();

      if (highValueTransactions.isNotEmpty) {
        await _pushService.showSpendingAlert(
          message: 'You\'ve made ${highValueTransactions.length} high-value transaction(s) this week. Review your recent spending.',
          transactionCount: highValueTransactions.length,
        );
      }
    }
  }

  // Schedule weekly summary
  Future<void> scheduleWeeklySummary({
    required String userId,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
  }) async {
    try {
      // Cancel existing weekly summary
      await _pushService.cancelNotification(9999);
      
      // Schedule new weekly summary
      await _pushService.scheduleWeeklySummary(
        id: 9999,
        title: 'Weekly Financial Summary',
        body: 'Your weekly financial summary is ready. Check your progress and insights!',
        dayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
        payload: 'weekly_summary:$userId',
      );

      // Save schedule to user preferences
      await _saveNotificationSchedule(userId, 'weekly_summary', {
        'dayOfWeek': dayOfWeek,
        'hour': hour,
        'minute': minute,
        'enabled': true,
      });
    } catch (e) {
      throw Exception('Failed to schedule weekly summary: $e');
    }
  }

  // Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required String userId,
    required int hour,
    required int minute,
    required String reminderType, // 'budget_check', 'goal_update', 'expense_log'
  }) async {
    try {
      final reminderId = _getReminderId(reminderType);
      
      // Cancel existing reminder
      await _pushService.cancelNotification(reminderId);
      
      // Schedule new reminder
      await _pushService.scheduleDailyReminder(
        id: reminderId,
        title: _getReminderTitle(reminderType),
        body: _getReminderBody(reminderType),
        hour: hour,
        minute: minute,
        payload: 'daily_reminder:$userId:$reminderType',
      );

      // Save schedule to user preferences
      await _saveNotificationSchedule(userId, 'daily_reminder_$reminderType', {
        'hour': hour,
        'minute': minute,
        'enabled': true,
        'type': reminderType,
      });
    } catch (e) {
      throw Exception('Failed to schedule daily reminder: $e');
    }
  }

  // Schedule budget alerts
  Future<void> scheduleBudgetAlerts({
    required String userId,
    required List<Budget> budgets,
  }) async {
    try {
      for (final budget in budgets) {
        if (!budget.isActive) continue;

        // Schedule alert for 80% usage
        final alertId = budget.id.hashCode + 1000;
        await _pushService.cancelNotification(alertId);
        
        // Calculate when budget will likely hit 80%
        final dailySpending = _calculateDailySpending(budget);
        if (dailySpending > 0) {
          final daysTo80Percent = ((budget.amount * 0.8) - budget.spent) / dailySpending;
          if (daysTo80Percent > 0 && daysTo80Percent <= 7) {
            final alertDate = DateTime.now().add(Duration(days: daysTo80Percent.round()));
            await _pushService.scheduleNotification(
              id: alertId,
              title: 'Budget Alert: ${budget.name}',
              body: 'Your ${budget.name} budget is approaching 80% usage. Consider monitoring your spending.',
              scheduledDate: alertDate,
              priority: NotificationPriority.high,
              payload: 'budget_alert:${budget.id}',
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to schedule budget alerts: $e');
    }
  }

  // Calculate daily spending for a budget
  double _calculateDailySpending(Budget budget) {
    // This is a simplified calculation - in a real app, you'd analyze historical data
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = now.difference(monthStart).inDays + 1;
    
    return budget.spent / daysInMonth;
  }

  // Get reminder ID based on type
  int _getReminderId(String reminderType) {
    switch (reminderType) {
      case 'budget_check':
        return 1001;
      case 'goal_update':
        return 1002;
      case 'expense_log':
        return 1003;
      default:
        return 1000;
    }
  }

  // Get reminder title
  String _getReminderTitle(String reminderType) {
    switch (reminderType) {
      case 'budget_check':
        return 'Budget Check Reminder';
      case 'goal_update':
        return 'Goal Progress Update';
      case 'expense_log':
        return 'Log Your Expenses';
      default:
        return 'Daily Reminder';
    }
  }

  // Get reminder body
  String _getReminderBody(String reminderType) {
    switch (reminderType) {
      case 'budget_check':
        return 'Time to check your budget progress and spending habits!';
      case 'goal_update':
        return 'Update your goal progress and stay motivated!';
      case 'expense_log':
        return 'Don\'t forget to log your expenses for today.';
      default:
        return 'Your daily financial reminder is here!';
    }
  }

  // Save notification schedule to user preferences
  Future<void> _saveNotificationSchedule(
    String userId,
    String scheduleType,
    Map<String, dynamic> scheduleData,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'notificationSchedules.$scheduleType': scheduleData,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ ENHANCED NOTIFICATION SERVICE: Error saving schedule: $e');
    }
  }

  // Get user notification schedules
  Future<Map<String, dynamic>> getUserNotificationSchedules(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        return Map<String, dynamic>.from(data['notificationSchedules'] ?? {});
      }
      return {};
    } catch (e) {
      print('❌ ENHANCED NOTIFICATION SERVICE: Error getting schedules: $e');
      return {};
    }
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    await _pushService.cancelAllNotifications();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _pushService.getPendingNotifications();
  }

  // Delegate methods to original notification service
  Future<List<Notification>> getUserNotifications(String userId) async {
    return await _notificationService.getUserNotifications(userId);
  }

  Future<List<Notification>> getUnreadNotifications(String userId) async {
    return await _notificationService.getUnreadNotifications(userId);
  }

  Future<void> markAsRead(String notificationId) async {
    return await _notificationService.markAsRead(notificationId);
  }

  Future<void> dismissNotification(String notificationId) async {
    return await _notificationService.dismissNotification(notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    return await _notificationService.deleteNotification(notificationId);
  }

  Future<bool> canGenerateSmartNotifications(String userId) async {
    return await _notificationService.canGenerateSmartNotifications(userId);
  }

  Future<Duration?> getTimeUntilNextGeneration(String userId) async {
    return await _notificationService.getTimeUntilNextGeneration(userId);
  }

  // Test notification methods
  Future<void> showBudgetAlert({
    required String budgetName,
    required double percentageUsed,
    required double remaining,
  }) async {
    await _pushService.showBudgetAlert(
      budgetName: budgetName,
      percentageUsed: percentageUsed,
      remaining: remaining,
    );
  }

  Future<void> showGoalMilestone({
    required String goalName,
    required double progress,
    required String milestone,
  }) async {
    await _pushService.showGoalMilestone(
      goalName: goalName,
      progress: progress,
      milestone: milestone,
    );
  }

  Future<void> showSpendingAlert({
    required String message,
    required int transactionCount,
  }) async {
    await _pushService.showSpendingAlert(
      message: message,
      transactionCount: transactionCount,
    );
  }

  Future<void> showFinancialTip({
    required String title,
    required String message,
  }) async {
    await _pushService.showFinancialTip(
      title: title,
      message: message,
    );
  }

  // --- Smart Daily Log Reminder Logic ---

  // Schedule the smart daily reminder (called on app init)
  Future<void> scheduleSmartDailyLogReminder(String userId) async {
    try {
      // 1. Check if user has already added transactions today
      final hasTransactions = await TransactionService().hasTransactionsToday(userId);
      
      // 2. Determine schedule time
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 17, 0); // Today 5 PM
      
      if (hasTransactions || now.isAfter(scheduledDate)) {
        // If already logged OR it's past 5 PM, schedule for tomorrow
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // 3. Schedule the notification
      // We use a specific ID for this smart reminder (e.g., 2000)
      await _pushService.scheduleNotification(
        id: 2000,
        title: 'Add your finances',
        body: 'You haven\'t added any finances today. Take a moment to log your expenses!',
        scheduledDate: scheduledDate,
        priority: NotificationPriority.high,
        payload: 'add_transaction',
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('✅ ENHANCED NOTIFICATION SERVICE: Scheduled smart reminder for $scheduledDate');
      
    } catch (e) {
      print('❌ ENHANCED NOTIFICATION SERVICE: Error scheduling smart reminder: $e');
    }
  }

  // Called when a transaction is added
  Future<void> updateDailyLogReminder(String userId) async {
    try {
      print('🔵 ENHANCED NOTIFICATION SERVICE: Transaction added, updating daily reminder...');
      
      // Cancel the current reminder for today
      await _pushService.cancelNotification(2000);
      
      // Schedule for tomorrow 5 PM
      final now = DateTime.now();
      final tomorrow5pm = DateTime(now.year, now.month, now.day, 17, 0).add(const Duration(days: 1));
      
      await _pushService.scheduleNotification(
        id: 2000,
        title: 'Add your finances',
        body: 'You haven\'t added any finances today. Take a moment to log your expenses!',
        scheduledDate: tomorrow5pm,
        priority: NotificationPriority.high,
        payload: 'add_transaction',
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('✅ ENHANCED NOTIFICATION SERVICE: Smart reminder pushed to tomorrow $tomorrow5pm');
      
    } catch (e) {
      print('❌ ENHANCED NOTIFICATION SERVICE: Error updating smart reminder: $e');
    }
  }

  // Schedule daily morning greeting (7 AM)
  Future<void> scheduleMorningGreeting(String userId) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 7, 0); // 7 AM
      
      // If 7 AM has passed, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _pushService.scheduleNotification(
        id: 7000,
        title: 'Good Morning ☀️',
        body: 'Rise and shine! Take a moment to track your finances today.',
        scheduledDate: scheduledDate,
        priority: NotificationPriority.low, // Less intrusive than alerts
        payload: 'morning_greeting',
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('✅ ENHANCED NOTIFICATION SERVICE: Scheduled morning greeting for $scheduledDate');
    } catch (e) {
      print('❌ ENHANCED NOTIFICATION SERVICE: Error scheduling morning greeting: $e');
    }
  }
}
