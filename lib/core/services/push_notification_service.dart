import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/notification_model.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notifications = fln.FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone with device location
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print('Failed to get local timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android initialization settings
    const androidSettings = fln.AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // iOS initialization settings
    const iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = fln.InitializationSettings(
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

    final androidDetails = fln.AndroidNotificationDetails(
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

    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = fln.NotificationDetails(
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
    fln.DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = fln.AndroidNotificationDetails(
      'flux_scheduled',
      'Scheduled Notifications',
      channelDescription: 'Scheduled notifications from Flux',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFF0079DC),
    );

    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    print('DEBUG: Scheduling notification id=$id, date=$scheduledDate');
    print('DEBUG: Timezone location: ${tz.local.name}');

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: payload,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      print('DEBUG: Successfully scheduled notification $id');
    } catch (e) {
      print('DEBUG: Failed in zonedSchedule: $e');
      rethrow;
    }
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

    print('DEBUG: daily scheduling - Now: $now');
    print('DEBUG: daily scheduling - Target (Naive): $scheduledDate');
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      print('DEBUG: Target is before Now, adding 1 day');
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Check exact alarm permission on Android
    final androidInfo = await fln.FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    print('DEBUG: Exact alarm permission request result: $androidInfo');

    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      priority: NotificationPriority.low,
      matchDateTimeComponents: fln.DateTimeComponents.time,
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
  Future<List<fln.PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Handle notification tap
  void _onNotificationTapped(fln.NotificationResponse response) {
    // Handle notification tap - you can navigate to specific screens
    // based on the payload
    print('Notification tapped: ${response.payload}');
  }

  // Convert priority to Android importance
  fln.Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return fln.Importance.low;
      case NotificationPriority.medium:
        return fln.Importance.defaultImportance;
      case NotificationPriority.high:
        return fln.Importance.high;
      case NotificationPriority.urgent:
        return fln.Importance.max;
    }
  }

  // Convert priority to Android priority
  fln.Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return fln.Priority.low;
      case NotificationPriority.medium:
        return fln.Priority.defaultPriority;
      case NotificationPriority.high:
        return fln.Priority.high;
      case NotificationPriority.urgent:
        return fln.Priority.max;
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
