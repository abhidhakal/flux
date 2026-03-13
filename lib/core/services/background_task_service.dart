import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enhanced_notification_service.dart';
import 'notification_trigger_service.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart' as model;
import '../models/goal_model.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      
      final userId = inputData?['userId'] as String?;
      if (userId == null) return true;

      final notificationService = EnhancedNotificationService();
      await notificationService.initialize();

      // For daily reminders/smart notifications, we perform a health check
      // This runs in the background even if the app is closed
      final firestore = FirebaseFirestore.instance;
      
      final budgetsDoc = await firestore.collection('budgets').where('userId', isEqualTo: userId).get();
      final transactionsDoc = await firestore.collection('transactions').where('userId', isEqualTo: userId).get();
      final goalsDoc = await firestore.collection('goals').where('userId', isEqualTo: userId).get();

      final budgetsData = budgetsDoc.docs.map((d) => d.data()).toList();
      final transactionsData = transactionsDoc.docs.map((d) => d.data()).toList();
      final goalsData = goalsDoc.docs.map((d) => d.data()).toList();

      final budgets = budgetsData.map((d) => Budget.fromJson(d)).toList();
      final transactions = transactionsData.map((d) => model.Transaction.fromJson(d)).toList();
      final goals = goalsData.map((d) => Goal.fromJson(d)).toList();

      // Perform a health check/sync via NotificationTriggerService
      final triggerService = NotificationTriggerService();
      await triggerService.monitorBudgetChanges(userId, budgets);
      await triggerService.monitorGoalProgress(userId, goals);
      await triggerService.monitorSpendingPatterns(userId, transactions);

      // Verify and re-schedule daily reminders if they somehow got lost
      // This is our 'Plan B' for reliability
      final userDoc = await firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData.containsKey('notificationSchedules')) {
        final schedules = userData['notificationSchedules'] as Map<String, dynamic>;
        
        // Skip background checks if user disabled them
        final checksEnabled = schedules['background_health_check']?['enabled'] ?? true;
        if (!checksEnabled) return true;

        final now = DateTime.now();
        
        if (schedules.containsKey('daily_reminder')) {
          final s = schedules['daily_reminder'];
          if (s['enabled'] == true) {
            final scheduledHour = (s['hour'] as num?)?.toInt() ?? 20;
            final scheduledMinute = (s['minute'] as num?)?.toInt() ?? 0;
            final hasPassedScheduledTime =
                now.hour > scheduledHour ||
                (now.hour == scheduledHour && now.minute >= scheduledMinute);

            if (hasPassedScheduledTime) {
               await triggerService.triggerDailyReminder(userId, s['type']);
            }
          }
        }
        
        if (schedules.containsKey('morning_greeting')) {
          final s = schedules['morning_greeting'];
          final scheduledHour = (s['hour'] as num?)?.toInt() ?? 8;
          final scheduledMinute = (s['minute'] as num?)?.toInt() ?? 0;
          final hasPassedScheduledTime =
              now.hour > scheduledHour ||
              (now.hour == scheduledHour && now.minute >= scheduledMinute);

          if (s['enabled'] == true && hasPassedScheduledTime) {
            await triggerService.triggerMorningGreeting(userId);
          }
        }
      }

      return true;
    } catch (e) {
      print('❌ WORKMANAGER: Task failed: $e');
      return false;
    }
  });
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  Future<void> registerDailyHealthCheck(String userId) async {
    await Workmanager().registerPeriodicTask(
      'daily_health_check_$userId',
      'dailyNotificationHealthCheck',
      frequency: const Duration(hours: 12),
      inputData: {'userId': userId},
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<void> cancelTasks(String userId) async {
    await Workmanager().cancelAll();
  }
}
