import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/notification_model.dart';
import '../constants/app_theme.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notifications =
      fln.FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) { _isInitialized = true; return; } // Not supported on web

    // Initialize timezone with device location
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Failed to get local timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android initialization settings
    const androidSettings =
        fln.AndroidInitializationSettings('@mipmap/launcher_icon');

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
    if (kIsWeb) return false; // Not supported on web
    if (!_isInitialized) await initialize();

    final status = await Permission.notification.request();

    final iosGranted = await _notifications
            .resolvePlatformSpecificImplementation<
                fln.IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    final macGranted = await _notifications
            .resolvePlatformSpecificImplementation<
                fln.MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;

    await _notifications
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    return status.isGranted && iosGranted && macGranted;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false; // Not supported on web
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
      color: AppColors.primary,
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
      color: AppColors.primary,
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

    debugPrint('DEBUG: Scheduling notification id=$id, date=$scheduledDate');
    debugPrint('DEBUG: Timezone location: ${tz.local.name}');

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
      debugPrint('DEBUG: Successfully scheduled notification $id');
    } catch (e) {
      debugPrint(
          'DEBUG: Failed exact zonedSchedule, retrying with inexact mode: $e');
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: payload,
        androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      debugPrint(
          'DEBUG: Successfully scheduled notification $id with inexact mode');
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

    debugPrint('DEBUG: daily scheduling - Now: $now');
    debugPrint('DEBUG: daily scheduling - Target (Naive): $scheduledDate');

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      debugPrint('DEBUG: Target is before Now, adding 1 day');
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Check exact alarm permission on Android
    final androidInfo = await _notifications
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    debugPrint('DEBUG: Exact alarm permission request result: $androidInfo');

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

  // Handle notification tap
  void _onNotificationTapped(fln.NotificationResponse response) {
    // Handle notification tap - you can navigate to specific screens
    // based on the payload
    debugPrint('Notification tapped: ${response.payload}');
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
}
