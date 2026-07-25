import 'package:home_widget/home_widget.dart';
import 'currency_service.dart';
import '../../features/goals/goals_bloc.dart';
import '../../features/transaction/transaction_bloc.dart';
import '../../core/models/goal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WidgetService {
  static const String _androidWidgetName = 'ActionWidgetProvider';
  static const String _androidBalanceWidgetName = 'BalanceWidgetProvider';
  static const String _androidQuickCaptureWidgetName =
      'QuickCaptureWidgetProvider';
  static const String _androidGoalWidgetName = 'GoalProgressWidgetProvider';

  static Future<void> updateBalanceWidget({
    required double balance,
    required double income,
    required double expenses,
    required int transactionCount,
  }) async {
    try {
      final currencyService = CurrencyService();
      await currencyService.ensureInitialized();

      await HomeWidget.saveWidgetData<String>(
          'balance', currencyService.formatAmount(balance));
      await HomeWidget.saveWidgetData<String>(
          'income', currencyService.formatAmount(income));
      await HomeWidget.saveWidgetData<String>(
          'expenses', currencyService.formatAmount(expenses));
      await HomeWidget.saveWidgetData<int>(
          'transactionCount', transactionCount);

      await HomeWidget.updateWidget(
        name: _androidBalanceWidgetName,
        androidName: _androidBalanceWidgetName,
      );
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
      await HomeWidget.updateWidget(
        name: _androidQuickCaptureWidgetName,
        androidName: _androidQuickCaptureWidgetName,
      );

      debugPrint('Widgets updated: balance=$balance');
    } catch (e) {
      debugPrint('Error updating balance widget: $e');
    }
  }

  static Future<void> updateGoalProgressWidget({
    required String goalName,
    required String goalCurrentAmount,
    required String goalTargetAmount,
    required int progress,
    required String goalStatus,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('goal_name', goalName);
      await HomeWidget.saveWidgetData<String>(
          'goal_current_amount', goalCurrentAmount);
      await HomeWidget.saveWidgetData<String>(
          'goal_target_amount', goalTargetAmount);
      await HomeWidget.saveWidgetData<int>(
          'goal_progress', progress.clamp(0, 100));
      await HomeWidget.saveWidgetData<String>('goal_status', goalStatus);

      await HomeWidget.updateWidget(
        name: _androidGoalWidgetName,
        androidName: _androidGoalWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating goal widget: $e');
    }
  }

  static void refreshWidgets(BuildContext context) {
    try {
      final transactionState = context.read<TransactionBloc>().state;
      final goalsState = context.read<GoalsBloc>().state;

      if (transactionState is TransactionLoaded) {
        final expenses =
            transactionState.transactions.where((t) => t.isExpense).toList();
        final incomes =
            transactionState.transactions.where((t) => t.isIncome).toList();
        final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
        final totalIncome = incomes.fold(0.0, (sum, t) => sum + t.amount);
        final balance = totalIncome - totalExpenses;

        updateBalanceWidget(
          balance: balance,
          income: totalIncome,
          expenses: totalExpenses,
          transactionCount: transactionState.transactions.length,
        );
      }

      if (goalsState is GoalsLoaded) {
        _refreshGoalWidget(goalsState.goals);
      }
    } catch (e) {
      debugPrint('Error refreshing widgets: $e');
    }
  }

  static Future<void> _refreshGoalWidget(List<Goal> goals) async {
    final currencyService = CurrencyService();
    await currencyService.ensureInitialized();

    final activeGoals =
        goals.where((goal) => goal.status == GoalStatus.active).toList()
          ..sort((a, b) {
            final progressComparison =
                b.progressPercentage.compareTo(a.progressPercentage);
            if (progressComparison != 0) return progressComparison;
            return a.targetDate.compareTo(b.targetDate);
          });

    if (activeGoals.isEmpty) {
      await updateGoalProgressWidget(
        goalName: 'Start your first goal',
        goalCurrentAmount: currencyService.formatAmount(0),
        goalTargetAmount: 'Set a target',
        progress: 0,
        goalStatus: 'No active goals',
      );
      return;
    }

    final selectedGoal = activeGoals.first;
    final goalStatus = selectedGoal.daysRemaining > 0
        ? '${selectedGoal.daysRemaining} days left'
        : 'Due now';

    await updateGoalProgressWidget(
      goalName: selectedGoal.name,
      goalCurrentAmount:
          currencyService.formatAmount(selectedGoal.currentAmount),
      goalTargetAmount: currencyService.formatAmount(selectedGoal.targetAmount),
      progress: selectedGoal.progressPercentage.round(),
      goalStatus: goalStatus,
    );
  }
}
