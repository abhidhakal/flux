import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../../features/budget/budget_bloc.dart';

class StaleBudgetHelper {
  static const String _lastCheckKey = 'last_stale_budget_check';

  /// Performs a check for stale budgets (≥95% spent and no transactions for 3 days).
  /// Only runs once every 24 hours.
  static Future<void> checkAndShowAlert(
    BuildContext context, {
    required List<Budget> budgets,
    required List<Transaction> transactions,
    required String userId,
  }) async {
    final budgetBloc = context.read<BudgetBloc>();
    final prefs = await SharedPreferences.getInstance();
    final lastCheckMillis = prefs.getInt('${_lastCheckKey}_$userId') ?? 0;
    final now = DateTime.now();

    // Only run once every 24 hours
    if (now.millisecondsSinceEpoch - lastCheckMillis < 24 * 60 * 60 * 1000) {
      return;
    }

    final staleBudgets = <_StaleBudgetInfo>[];

    for (final budget in budgets) {
      if (!budget.isActive) continue;

      final percentage = budget.progressPercentage;
      if (percentage < 95) continue;

      // Find the most recent transaction linked to this budget
      DateTime? lastTxDate;
      for (final tx in transactions) {
        if (tx.budgetId != budget.id) continue;
        if (lastTxDate == null || tx.date.isAfter(lastTxDate)) {
          lastTxDate = tx.date;
        }
      }

      final daysSinceTx =
          lastTxDate == null ? 999 : now.difference(lastTxDate).inDays;

      if (daysSinceTx >= 3) {
        staleBudgets.add(_StaleBudgetInfo(
          budget: budget,
          percentage: percentage.round(),
          daysSinceTx: daysSinceTx,
        ));
      }
    }

    if (staleBudgets.isNotEmpty && context.mounted) {
      // Record that we checked today
      await prefs.setInt(
          '${_lastCheckKey}_$userId', now.millisecondsSinceEpoch);
      if (!context.mounted) {
        return;
      }

      // Show dialog for the first stale budget found
      // (Or we could show a list if multiple are stale, but sticking to original behavior)
      final info = staleBudgets.first;
      _showStaleBudgetDialog(
        context,
        budgetBloc,
        info.budget,
        info.percentage,
        info.daysSinceTx,
      );
    }
  }

  static void _showStaleBudgetDialog(
    BuildContext context,
    BudgetBloc budgetBloc,
    Budget budget,
    int percentage,
    int daysSinceTx,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final daysLabel = daysSinceTx >= 999
        ? 'no transactions recorded'
        : '$daysSinceTx days ago';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Budget?'),
        content: Text(
          'Your "${budget.name}" budget is at $percentage% and the last transaction was $daysLabel. '
          'Would you like to mark it as inactive?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Keep Active',
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              budgetBloc.add(
                UpdateBudget(budget.copyWith(isActive: false)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

class _StaleBudgetInfo {
  final Budget budget;
  final int percentage;
  final int daysSinceTx;

  _StaleBudgetInfo({
    required this.budget,
    required this.percentage,
    required this.daysSinceTx,
  });
}
