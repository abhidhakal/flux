import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';

class NotificationService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a notification
  Future<void> createNotification(Notification notification) async {
    try {
      final notificationRef = _firestore.collection('notifications').doc(notification.id);
      await notificationRef.set(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get user notifications
  Future<List<Notification>> getUserNotifications(String userId) async {
    try {
      // Ensure user document exists
      await _ensureUserExists(userId);
      
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Notification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error getting user notifications: $e');
      return [];
    }
  }

  // Get unread notifications
  Future<List<Notification>> getUnreadNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.name)
          .get();

      return querySnapshot.docs
          .map((doc) => Notification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error getting unread notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final notificationRef = _firestore.collection('notifications').doc(notificationId);
      await notificationRef.update({
        'status': NotificationStatus.read.name,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Dismiss notification
  Future<void> dismissNotification(String notificationId) async {
    try {
      final notificationRef = _firestore.collection('notifications').doc(notificationId);
      await notificationRef.update({
        'status': NotificationStatus.dismissed.name,
        'dismissedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to dismiss notification: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final notificationRef = _firestore.collection('notifications').doc(notificationId);
      await notificationRef.delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Generate smart notifications based on user data
  Future<void> generateSmartNotifications(
    String userId,
    List<Budget> budgets,
    List<Transaction> transactions,
    List<Goal> goals,
  ) async {
    try {
      // Check if smart notifications were generated recently (within last hour)
      final lastGenerated = await _getLastSmartNotificationGeneration(userId);
      if (lastGenerated != null) {
        final timeSinceLastGeneration = DateTime.now().difference(lastGenerated);
        if (timeSinceLastGeneration.inHours < 1) {
          throw Exception('Smart notifications were already generated recently. Please wait ${60 - timeSinceLastGeneration.inMinutes} minutes before generating again.');
        }
      }

      // Budget alerts
      await _generateBudgetAlerts(userId, budgets);
      
      // Spending reminders
      await _generateSpendingReminders(userId, transactions);
      
      // Goal milestones
      await _generateGoalMilestones(userId, goals);
      
      // Financial tips
      await _generateFinancialTips(userId, transactions);
      
      // Savings reminders
      await _generateSavingsReminders(userId, transactions);
      
      // Debt alerts
      await _generateDebtAlerts(userId, transactions);
      
      // Update last generation timestamp
      await _updateLastSmartNotificationGeneration(userId);
      
    } catch (e) {
      throw Exception('Failed to generate smart notifications: $e');
    }
  }

  // Budget alerts
  Future<void> _generateBudgetAlerts(String userId, List<Budget> budgets) async {
    for (final budget in budgets) {
      if (!budget.isActive) continue;

      final percentageUsed = (budget.spent / budget.amount) * 100;
      
      if (percentageUsed >= 90 && percentageUsed < 100) {
        await createNotification(Notification(
          id: _uuid.v4(),
          userId: userId,
          title: 'Budget Alert: ${budget.name}',
          message: 'You\'ve used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.name} budget. Consider reducing spending in this category.',
          type: NotificationType.budgetAlert,
          priority: NotificationPriority.high,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'budgetId': budget.id,
            'budgetName': budget.name,
            'percentageUsed': percentageUsed,
            'remaining': budget.remaining,
          },
          isActionable: true,
          actionTitle: 'View Budget',
          actionRoute: '/budgets',
        ));
      } else if (percentageUsed >= 100) {
        await createNotification(Notification(
          id: _uuid.v4(),
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
          },
          isActionable: true,
          actionTitle: 'Review Budget',
          actionRoute: '/budgets',
        ));
      }
    }
  }

  // Spending reminders
  Future<void> _generateSpendingReminders(String userId, List<Transaction> transactions) async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    
    // Check for unusual spending patterns
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(lastWeek) && t.isExpense)
        .toList();

    if (recentTransactions.isNotEmpty) {
      final totalSpent = recentTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final averageSpent = totalSpent / recentTransactions.length;
      
      // Check for high-value transactions
      final highValueTransactions = recentTransactions
          .where((t) => t.amount > averageSpent * 2)
          .toList();

      if (highValueTransactions.isNotEmpty) {
        await createNotification(Notification(
          id: _uuid.v4(),
          userId: userId,
          title: 'Unusual Spending Detected',
          message: 'You\'ve made ${highValueTransactions.length} high-value transaction(s) this week. Review your recent spending.',
          type: NotificationType.spendingReminder,
          priority: NotificationPriority.medium,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'highValueCount': highValueTransactions.length,
            'totalSpent': totalSpent,
            'averageSpent': averageSpent,
          },
          isActionable: true,
          actionTitle: 'View Transactions',
          actionRoute: '/transactions',
        ));
      }
    }
  }

  // Goal milestones
  Future<void> _generateGoalMilestones(String userId, List<Goal> goals) async {
    for (final goal in goals) {
      if (goal.status != GoalStatus.active) continue;

      final progress = goal.progressPercentage;
      
      // 25% milestone
      if (progress >= 25 && progress < 30) {
        await createNotification(Notification(
          id: _uuid.v4(),
          userId: userId,
          title: 'Goal Milestone: ${goal.name}',
          message: 'Congratulations! You\'ve reached 25% of your ${goal.name} goal. Keep up the great work!',
          type: NotificationType.goalMilestone,
          priority: NotificationPriority.medium,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'goalId': goal.id,
            'goalName': goal.name,
            'progress': progress,
            'milestone': '25%',
          },
          isActionable: true,
          actionTitle: 'View Goal',
          actionRoute: '/goals',
        ));
      }
      
      // 50% milestone
      if (progress >= 50 && progress < 55) {
        await createNotification(Notification(
          id: _uuid.v4(),
          userId: userId,
          title: 'Halfway There: ${goal.name}',
          message: 'Amazing! You\'re halfway to your ${goal.name} goal. You\'re doing fantastic!',
          type: NotificationType.goalMilestone,
          priority: NotificationPriority.high,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'goalId': goal.id,
            'goalName': goal.name,
            'progress': progress,
            'milestone': '50%',
          },
          isActionable: true,
          actionTitle: 'View Goal',
          actionRoute: '/goals',
        ));
      }
      
      // 90% milestone
      if (progress >= 90 && progress < 95) {
        await createNotification(Notification(
          id: _uuid.v4(),
          userId: userId,
          title: 'Almost There: ${goal.name}',
          message: 'You\'re so close! Just ${goal.remaining.toStringAsFixed(2)} left to reach your ${goal.name} goal.',
          type: NotificationType.goalMilestone,
          priority: NotificationPriority.high,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'goalId': goal.id,
            'goalName': goal.name,
            'progress': progress,
            'remaining': goal.remaining,
            'milestone': '90%',
          },
          isActionable: true,
          actionTitle: 'View Goal',
          actionRoute: '/goals',
        ));
      }
      
      // Goal completed
      if (goal.isCompleted && goal.completedAt != null) {
        final daysSinceCompletion = DateTime.now().difference(goal.completedAt!).inDays;
        if (daysSinceCompletion <= 1) {
          await createNotification(Notification(
            id: _uuid.v4(),
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
              'completedAt': goal.completedAt!.toIso8601String(),
            },
            isActionable: true,
            actionTitle: 'View Achievement',
            actionRoute: '/goals',
          ));
        }
      }
    }
  }

  // Financial tips
  Future<void> _generateFinancialTips(String userId, List<Transaction> transactions) async {
    final tips = [
      {
        'title': 'Save More with the 50/30/20 Rule',
        'message': 'Consider allocating 50% to needs, 30% to wants, and 20% to savings. This simple rule can transform your finances.',
        'priority': NotificationPriority.low,
      },
      {
        'title': 'Track Your Spending',
        'message': 'You\'ve been tracking your expenses well! Keep it up - awareness is the first step to better financial habits.',
        'priority': NotificationPriority.low,
      },
      {
        'title': 'Emergency Fund Reminder',
        'message': 'Aim to save 3-6 months of expenses in an emergency fund. This provides security during unexpected situations.',
        'priority': NotificationPriority.medium,
      },
      {
        'title': 'Review Your Budget Regularly',
        'message': 'Regular budget reviews help you stay on track and adjust to changing circumstances.',
        'priority': NotificationPriority.medium,
      },
      {
        'title': 'Pay Yourself First',
        'message': 'Set aside savings before paying bills. This ensures you prioritize your financial future.',
        'priority': NotificationPriority.medium,
      },
    ];

    // Randomly select a tip (in a real app, you'd rotate through them)
    final randomTip = tips[DateTime.now().millisecondsSinceEpoch % tips.length];
    
    await createNotification(Notification(
      id: _uuid.v4(),
      userId: userId,
      title: randomTip['title'] as String,
      message: randomTip['message'] as String,
      type: NotificationType.financialTip,
      priority: randomTip['priority'] as NotificationPriority,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      isActionable: false,
    ));
  }

  // Savings reminders
  Future<void> _generateSavingsReminders(String userId, List<Transaction> transactions) async {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    
    final monthlyTransactions = transactions
        .where((t) => t.date.isAfter(lastMonth))
        .toList();

    if (monthlyTransactions.isNotEmpty) {
      final totalIncome = monthlyTransactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final totalExpenses = monthlyTransactions
          .where((t) => t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final savings = totalIncome - totalExpenses;
      final savingsRate = totalIncome > 0 ? (savings / totalIncome) * 100 : 0;

      if (savingsRate < 10) {
        await createNotification(Notification(
          id: _uuid.v4(),
          userId: userId,
          title: 'Low Savings Rate Alert',
          message: 'Your savings rate is ${savingsRate.toStringAsFixed(1)}%. Consider increasing your savings to build wealth faster.',
          type: NotificationType.savingsReminder,
          priority: NotificationPriority.high,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'savingsRate': savingsRate,
            'totalIncome': totalIncome,
            'totalExpenses': totalExpenses,
            'savings': savings,
          },
          isActionable: true,
          actionTitle: 'Review Spending',
          actionRoute: '/analytics',
        ));
      } else if (savingsRate >= 20) {
        await createNotification(Notification(
          id: _uuid.v4(),
          userId: userId,
          title: 'Great Savings Rate!',
          message: 'Excellent work! Your ${savingsRate.toStringAsFixed(1)}% savings rate is above the recommended 20%. Keep it up!',
          type: NotificationType.achievement,
          priority: NotificationPriority.low,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'savingsRate': savingsRate,
            'totalIncome': totalIncome,
            'savings': savings,
          },
          isActionable: true,
          actionTitle: 'View Progress',
          actionRoute: '/analytics',
        ));
      }
    }
  }

  // Debt alerts
  Future<void> _generateDebtAlerts(String userId, List<Transaction> transactions) async {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    
    final monthlyTransactions = transactions
        .where((t) => t.date.isAfter(lastMonth))
        .toList();

    if (monthlyTransactions.isNotEmpty) {
      final totalIncome = monthlyTransactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final debtPayments = monthlyTransactions
          .where((t) => t.isExpense && t.category.toLowerCase().contains('debt'))
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final debtToIncomeRatio = totalIncome > 0 ? (debtPayments / totalIncome) * 100 : 0;

      if (debtToIncomeRatio > 40) {
        await createNotification(Notification(
          id: _uuid.v4(),
          userId: userId,
          title: 'High Debt-to-Income Ratio',
          message: 'Your debt payments are ${debtToIncomeRatio.toStringAsFixed(1)}% of your income. Consider debt consolidation or repayment strategies.',
          type: NotificationType.debtAlert,
          priority: NotificationPriority.urgent,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: {
            'debtToIncomeRatio': debtToIncomeRatio,
            'totalIncome': totalIncome,
            'debtPayments': debtPayments,
          },
          isActionable: true,
          actionTitle: 'Get Help',
          actionRoute: '/goals',
        ));
      }
    }
  }

  // Generate unique ID
  String generateId() {
    return _uuid.v4();
  }

  // Get last smart notification generation time
  Future<DateTime?> _getLastSmartNotificationGeneration(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final lastGenerated = data['lastSmartNotificationGeneration'];
        if (lastGenerated != null) {
          return DateTime.parse(lastGenerated);
        }
      }
      return null;
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error getting last generation time: $e');
      return null;
    }
  }

  // Update last smart notification generation time
  Future<void> _updateLastSmartNotificationGeneration(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'lastSmartNotificationGeneration': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error updating last generation time: $e');
      // Don't throw here to prevent cascading failures
    }
  }

  // Check if smart notifications can be generated (not within cooldown period)
  Future<bool> canGenerateSmartNotifications(String userId) async {
    try {
      final lastGenerated = await _getLastSmartNotificationGeneration(userId);
      if (lastGenerated == null) return true;
      
      final timeSinceLastGeneration = DateTime.now().difference(lastGenerated);
      return timeSinceLastGeneration.inHours >= 1;
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error checking generation eligibility: $e');
      return true; // Allow generation if there's an error
    }
  }

  // Get time until next generation is allowed
  Future<Duration?> getTimeUntilNextGeneration(String userId) async {
    try {
      final lastGenerated = await _getLastSmartNotificationGeneration(userId);
      if (lastGenerated == null) return null;
      
      final timeSinceLastGeneration = DateTime.now().difference(lastGenerated);
      if (timeSinceLastGeneration.inHours >= 1) return null;
      
      return Duration(minutes: 60 - timeSinceLastGeneration.inMinutes);
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error getting time until next generation: $e');
      return null;
    }
  }

  // Private method to ensure user document exists
  Future<void> _ensureUserExists(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        print('⚠️ NOTIFICATION SERVICE: User not found, creating user document');
        // Create basic user document if it doesn't exist
        await _firestore
            .collection('users')
            .doc(userId)
            .set({
          'id': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'lastLoginAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error ensuring user exists: $e');
      // Don't throw here to prevent cascading failures
    }
  }
}
