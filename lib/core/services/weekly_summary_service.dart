import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/income_model.dart';
import '../models/goal_model.dart';
import 'enhanced_notification_service.dart';
import 'currency_service.dart';

class WeeklySummaryService {
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Generate and send weekly summary
  Future<void> generateWeeklySummary(String userId) async {
    try {
      // Get user data for the past week
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      
      final budgets = await _getUserBudgets(userId);
      final transactions = await _getUserTransactions(userId, weekStart);
      final incomes = await _getUserIncome(userId, weekStart);
      final goals = await _getUserGoals(userId);

      // Generate summary data
      final summaryData = _generateSummaryData(transactions, incomes, budgets, goals);
      
      // Create and send notification
      await _sendWeeklySummaryNotification(userId, summaryData);
      
      // Save summary to user's history
      await _saveWeeklySummary(userId, summaryData);
      
    } catch (e) {
      print('❌ WEEKLY SUMMARY: Error generating weekly summary: $e');
    }
  }

  // Get user budgets
  Future<List<Budget>> _getUserBudgets(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Budget.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ WEEKLY SUMMARY: Error getting budgets: $e');
      return [];
    }
  }

  // Get user transactions for the week
  Future<List<Transaction>> _getUserTransactions(String userId, DateTime weekStart) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: weekStart)
          .get();

      return querySnapshot.docs
          .map((doc) => Transaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ WEEKLY SUMMARY: Error getting transactions: $e');
      return [];
    }
  }

  // Get user goals
  Future<List<Goal>> _getUserGoals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: GoalStatus.active.name)
          .get();

      return querySnapshot.docs
          .map((doc) => Goal.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ WEEKLY SUMMARY: Error getting goals: $e');
      return [];
    }
  }

  // Get user income for the week
  Future<List<Income>> _getUserIncome(String userId, DateTime weekStart) async {
    try {
      final querySnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: weekStart)
          .get();

      return querySnapshot.docs
          .map((doc) => Income.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ WEEKLY SUMMARY: Error getting income: $e');
      return [];
    }
  }

  // Generate summary data
  Map<String, dynamic> _generateSummaryData(
    List<Transaction> transactions,
    List<Income> incomes,
    List<Budget> budgets,
    List<Goal> goals,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    
    // Calculate income and expenses
    final weeklyIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    
    final weeklyExpenses = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final netIncome = weeklyIncome - weeklyExpenses;
    
    // Calculate budget performance
    final budgetPerformance = _calculateBudgetPerformance(budgets);
    
    // Calculate goal progress
    final goalProgress = _calculateGoalProgress(goals);
    
    // Calculate spending by category
    final spendingByCategory = _calculateSpendingByCategory(transactions);
    
    // Calculate insights
    final insights = _generateInsights(transactions, incomes, budgets, goals);
    
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': now.toIso8601String(),
      'weeklyIncome': weeklyIncome,
      'weeklyExpenses': weeklyExpenses,
      'netIncome': netIncome,
      'budgetPerformance': budgetPerformance,
      'goalProgress': goalProgress,
      'spendingByCategory': spendingByCategory,
      'insights': insights,
      'generatedAt': now.toIso8601String(),
    };
  }

  // Calculate budget performance
  Map<String, dynamic> _calculateBudgetPerformance(List<Budget> budgets) {
    if (budgets.isEmpty) {
      return {
        'totalBudgets': 0,
        'budgetsOnTrack': 0,
        'budgetsOver': 0,
        'totalBudgetAmount': 0.0,
        'totalSpent': 0.0,
        'averageUsage': 0.0,
      };
    }

    int budgetsOnTrack = 0;
    int budgetsOver = 0;
    double totalBudgetAmount = 0.0;
    double totalSpent = 0.0;

    for (final budget in budgets) {
      totalBudgetAmount += budget.amount;
      totalSpent += budget.spent;
      
      final percentageUsed = (budget.spent / budget.amount) * 100;
      if (percentageUsed <= 100) {
        budgetsOnTrack++;
      } else {
        budgetsOver++;
      }
    }

    final averageUsage = totalBudgetAmount > 0 ? (totalSpent / totalBudgetAmount) * 100 : 0.0;

    return {
      'totalBudgets': budgets.length,
      'budgetsOnTrack': budgetsOnTrack,
      'budgetsOver': budgetsOver,
      'totalBudgetAmount': totalBudgetAmount,
      'totalSpent': totalSpent,
      'averageUsage': averageUsage,
    };
  }

  // Calculate goal progress
  Map<String, dynamic> _calculateGoalProgress(List<Goal> goals) {
    if (goals.isEmpty) {
      return {
        'totalGoals': 0,
        'totalTargetAmount': 0.0,
        'totalCurrentAmount': 0.0,
        'averageProgress': 0.0,
        'goalsNearCompletion': 0,
      };
    }

    double totalTargetAmount = 0.0;
    double totalCurrentAmount = 0.0;
    int goalsNearCompletion = 0;

    for (final goal in goals) {
      totalTargetAmount += goal.targetAmount;
      totalCurrentAmount += goal.currentAmount;
      
      if (goal.progressPercentage >= 75) {
        goalsNearCompletion++;
      }
    }

    final averageProgress = totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) * 100 : 0.0;

    return {
      'totalGoals': goals.length,
      'totalTargetAmount': totalTargetAmount,
      'totalCurrentAmount': totalCurrentAmount,
      'averageProgress': averageProgress,
      'goalsNearCompletion': goalsNearCompletion,
    };
  }

  // Calculate spending by category
  Map<String, double> _calculateSpendingByCategory(List<Transaction> transactions) {
    final spendingByCategory = <String, double>{};
    
    for (final transaction in transactions.where((t) => t.isExpense)) {
      spendingByCategory[transaction.category] = 
          (spendingByCategory[transaction.category] ?? 0.0) + transaction.amount;
    }
    
    return spendingByCategory;
  }

  // Generate insights
  List<String> _generateInsights(
    List<Transaction> transactions,
    List<Income> incomes,
    List<Budget> budgets,
    List<Goal> goals,
  ) {
    final insights = <String>[];
    
    // Income vs Expenses insight
    final weeklyIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final weeklyExpenses = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    if (weeklyIncome > 0) {
      final savingsRate = ((weeklyIncome - weeklyExpenses) / weeklyIncome) * 100;
      if (savingsRate > 20) {
        insights.add('Great job! Your savings rate is ${savingsRate.toStringAsFixed(1)}% this week.');
      } else if (savingsRate < 0) {
        insights.add('You spent more than you earned this week. Consider reviewing your expenses.');
      } else {
        insights.add('Your savings rate is ${savingsRate.toStringAsFixed(1)}% this week.');
      }
    }
    
    // Budget insights
    if (budgets.isNotEmpty) {
      final overBudgetCount = budgets.where((b) => b.spent > b.amount).length;
      if (overBudgetCount == 0) {
        insights.add('Excellent! You stayed within all your budget limits this week.');
      } else {
        insights.add('You exceeded $overBudgetCount budget(s) this week. Review your spending habits.');
      }
    }
    
    // Goal insights
    if (goals.isNotEmpty) {
      final nearCompletionGoals = goals.where((g) => g.progressPercentage >= 75).length;
      if (nearCompletionGoals > 0) {
        insights.add('You\'re close to completing $nearCompletionGoals goal(s)! Keep up the momentum.');
      }
    }
    
    // Spending pattern insights
    final spendingByCategory = _calculateSpendingByCategory(transactions);
    if (spendingByCategory.isNotEmpty) {
      final topCategory = spendingByCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add('Your top spending category this week was ${topCategory.key} (${CurrencyService().formatAmount(topCategory.value).replaceAll('.00', '')}).');
    }
    
    return insights;
  }

  // Send weekly summary notification
  Future<void> _sendWeeklySummaryNotification(String userId, Map<String, dynamic> summaryData) async {
    try {
      final weeklyIncome = summaryData['weeklyIncome'] as double;
      final weeklyExpenses = summaryData['weeklyExpenses'] as double;
      final netIncome = summaryData['netIncome'] as double;
      final insights = summaryData['insights'] as List<String>;
      
      final title = 'Weekly Financial Summary';
      final message = _buildSummaryMessage(weeklyIncome, weeklyExpenses, netIncome, insights);
      
      await _notificationService.createNotificationWithPush(
        Notification(
          id: _uuid.v4(),
          userId: userId,
          title: title,
          message: message,
          type: NotificationType.financialTip,
          priority: NotificationPriority.medium,
          status: NotificationStatus.unread,
          createdAt: DateTime.now(),
          metadata: summaryData,
          isActionable: true,
          actionTitle: 'View Full Summary',
          actionRoute: '/analytics',
        ),
      );
    } catch (e) {
      print('❌ WEEKLY SUMMARY: Error sending notification: $e');
    }
  }

  // Build summary message
  String _buildSummaryMessage(double income, double expenses, double netIncome, List<String> insights) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 Your weekly financial summary:');
    buffer.writeln('💰 Income: \$${income.toStringAsFixed(2)}');
    buffer.writeln('💸 Expenses: \$${expenses.toStringAsFixed(2)}');
    buffer.writeln('📈 Net: \$${netIncome.toStringAsFixed(2)}');
    
    if (insights.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('💡 Key insights:');
      for (final insight in insights.take(2)) {
        buffer.writeln('• $insight');
      }
    }
    
    return buffer.toString();
  }

  // Save weekly summary to user's history
  Future<void> _saveWeeklySummary(String userId, Map<String, dynamic> summaryData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weekly_summaries')
          .doc(summaryData['weekEnd'])
          .set(summaryData);
    } catch (e) {
      print('❌ WEEKLY SUMMARY: Error saving summary: $e');
    }
  }

  // Get user's weekly summary history
  Future<List<Map<String, dynamic>>> getWeeklySummaryHistory(String userId, {int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weekly_summaries')
          .orderBy('generatedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('❌ WEEKLY SUMMARY: Error getting history: $e');
      return [];
    }
  }
}
