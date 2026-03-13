import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';
import 'transaction_service.dart';

class EnhancedNotificationService {
  static const int _smartDailyReminderId = 2000;
  static const int _morningGreetingId = 7000;

  final NotificationService _notificationService = NotificationService();
  final PushNotificationService _pushService = PushNotificationService();
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  // ignore: unused_field
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

  // Daily Reminders Logic
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
      await _saveNotificationSchedule(userId, 'daily_reminder', {
        'hour': hour,
        'minute': minute,
        'enabled': true,
        'type': reminderType,
        'lastScheduled': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to schedule daily reminder: $e');
    }
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

  Future<void> cancelDailyReminder(String userId) async {
    await _pushService.cancelNotification(_getReminderId('budget_check'));
    await _pushService.cancelNotification(_getReminderId('goal_update'));
    await _pushService.cancelNotification(_getReminderId('expense_log'));
    await _saveNotificationSchedule(userId, 'daily_reminder', {
      'enabled': false,
      'cancelledAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> cancelMorningGreeting(String userId) async {
    await _pushService.cancelNotification(_morningGreetingId);
    await _saveNotificationSchedule(userId, 'morning_greeting', {
      'enabled': false,
      'cancelledAt': DateTime.now().toIso8601String(),
    });
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

  Future<void> deleteAllNotifications(String userId) async {
    return await _notificationService.deleteAllNotifications(userId);
  }

  Future<void> markAllAsRead(String userId) async {
    return await _notificationService.markAllAsRead(userId);
  }

  Future<bool> canGenerateSmartNotifications(String userId) async {
    return await _notificationService.canGenerateSmartNotifications(userId);
  }

  Future<Duration?> getTimeUntilNextGeneration(String userId) async {
    return await _notificationService.getTimeUntilNextGeneration(userId);
  }

  Future<void> updateLastSmartNotificationGeneration(String userId) async {
    return await _notificationService.updateLastSmartNotificationGeneration(userId);
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
      // 0. Check if user already has a custom daily reminder set
      final schedules = await getUserNotificationSchedules(userId);
      if (schedules['daily_reminder']?['enabled'] == true) {
        print('🔵 ENHANCED NOTIFICATION SERVICE: Custom daily reminder enabled, skipping smart reminder.');
        return;
      }

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
        id: _smartDailyReminderId,
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
      await _pushService.cancelNotification(_smartDailyReminderId);
      
      // Schedule for tomorrow 5 PM
      final now = DateTime.now();
      final tomorrow5pm = DateTime(now.year, now.month, now.day, 17, 0).add(const Duration(days: 1));
      
      await _pushService.scheduleNotification(
        id: _smartDailyReminderId,
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
  Future<void> scheduleMorningGreeting(String userId, {bool force = false}) async {
    try {
      if (!force) {
        final schedules = await getUserNotificationSchedules(userId);
        if (schedules['morning_greeting']?['enabled'] != true) {
          print('🔵 ENHANCED NOTIFICATION SERVICE: Morning greeting disabled, skipping schedule.');
          return;
        }
      }

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 8, 0); // 8 AM
      
      // If 8 AM has passed, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _pushService.cancelNotification(_morningGreetingId);

      await _pushService.scheduleNotification(
        id: _morningGreetingId,
        title: 'Good Morning ☀️',
        body: 'Rise and shine! Take a moment to track your finances today.',
        scheduledDate: scheduledDate,
        priority: NotificationPriority.low, // Less intrusive than alerts
        payload: 'morning_greeting',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _saveNotificationSchedule(userId, 'morning_greeting', {
        'enabled': true,
        'hour': 8,
        'minute': 0,
        'lastScheduled': DateTime.now().toIso8601String(),
      });
      
      print('✅ ENHANCED NOTIFICATION SERVICE: Scheduled morning greeting for $scheduledDate');
    } catch (e) {
      print('❌ ENHANCED NOTIFICATION SERVICE: Error scheduling morning greeting: $e');
    }
  }
}
