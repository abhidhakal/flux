import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.medium,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'flux_notifications',
      'Flux Notifications',
      channelDescription: 'Notifications from Flux financial app',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFF0079DC),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Schedule notification for specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationPriority priority = NotificationPriority.medium,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'flux_scheduled',
      'Scheduled Notifications',
      channelDescription: 'Scheduled notifications from Flux',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFF0079DC),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  // Schedule weekly summary notification
  Future<void> scheduleWeeklySummary({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Find next occurrence of the specified day
    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      priority: NotificationPriority.medium,
    );
  }

  // Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      priority: NotificationPriority.low,
    );
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - you can navigate to specific screens
    // based on the payload
    print('Notification tapped: ${response.payload}');
  }

  // Convert priority to Android importance
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  // Convert priority to Android priority
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  // Generate unique notification ID
  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch % 2147483647;
  }

  // Show budget alert notification
  Future<void> showBudgetAlert({
    required String budgetName,
    required double percentageUsed,
    required double remaining,
  }) async {
    final title = percentageUsed >= 100 
        ? 'Budget Exceeded: $budgetName'
        : 'Budget Alert: $budgetName';
    
    final body = percentageUsed >= 100
        ? 'You\'ve exceeded your $budgetName budget. Review your spending habits.'
        : 'You\'ve used ${percentageUsed.toStringAsFixed(1)}% of your $budgetName budget. Consider reducing spending.';

    await showNotification(
      id: _generateNotificationId(),
      title: title,
      body: body,
      priority: percentageUsed >= 100 ? NotificationPriority.urgent : NotificationPriority.high,
      payload: 'budget_alert:$budgetName',
    );
  }

  // Show goal milestone notification
  Future<void> showGoalMilestone({
    required String goalName,
    required double progress,
    required String milestone,
  }) async {
    final title = 'Goal Milestone: $goalName';
    final body = 'Congratulations! You\'ve reached $milestone of your $goalName goal. Keep up the great work!';

    await showNotification(
      id: _generateNotificationId(),
      title: title,
      body: body,
      priority: NotificationPriority.high,
      payload: 'goal_milestone:$goalName',
    );
  }

  // Show spending alert notification
  Future<void> showSpendingAlert({
    required String message,
    required int transactionCount,
  }) async {
    await showNotification(
      id: _generateNotificationId(),
      title: 'Unusual Spending Detected',
      body: message,
      priority: NotificationPriority.medium,
      payload: 'spending_alert:$transactionCount',
    );
  }

  // Show weekly summary notification
  Future<void> showWeeklySummary({
    required String title,
    required String body,
  }) async {
    await showNotification(
      id: _generateNotificationId(),
      title: title,
      body: body,
      priority: NotificationPriority.medium,
      payload: 'weekly_summary',
    );
  }

  // Show financial tip notification
  Future<void> showFinancialTip({
    required String title,
    required String message,
  }) async {
    await showNotification(
      id: _generateNotificationId(),
      title: title,
      body: message,
      priority: NotificationPriority.low,
      payload: 'financial_tip',
    );
  }
}
