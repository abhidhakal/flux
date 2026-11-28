import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/auth/auth_bloc.dart';
import '../../features/budget/budget_bloc.dart';
import '../../features/goals/goals_bloc.dart';
import '../../features/transaction/transaction_bloc.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import 'currency_service.dart';
import 'recurring_transaction_service.dart';

/// Computes everything the Android home-screen widgets show and hands it to
/// the native side as plain strings/ints. Kotlin only lays out and draws.
class WidgetService {
  // Receiver class names. The first four keep the old names so widgets
  // users already placed keep working after the update.
  static const _providers = [
    'ActionWidgetProvider', // Safe to spend
    'QuickCaptureWidgetProvider', // Quick add
    'GoalProgressWidgetProvider', // Goal jar
    'BalanceWidgetProvider', // Month at a glance
    'SpendingPulseWidgetProvider',
    'BudgetRingsWidgetProvider',
    'UpcomingBillsWidgetProvider',
    'HeatmapWidgetProvider',
    'StreakWidgetProvider',
    'TopCategoryWidgetProvider',
  ];

  /// Categories that don't break a no-spend streak.
  static const _essential = {
    'Bills & Utilities',
    'Housing',
    'Insurance',
    'Healthcare',
    'Education',
  };

  static void refreshWidgets(BuildContext context) {
    if (kIsWeb) return;
    final tx = context.read<TransactionBloc>().state;
    final budgets = context.read<BudgetBloc>().state;
    final goals = context.read<GoalsBloc>().state;
    final auth = context.read<AuthBloc>().state;
    _refresh(
      tx is TransactionLoaded ? tx.transactions : null,
      budgets is BudgetLoaded ? budgets.budgets : null,
      goals is GoalsLoaded ? goals.goals : null,
      auth is AuthAuthenticated ? auth.user.id : null,
    );
  }

  static Future<void> _refresh(List<Transaction>? txs, List<Budget>? budgets,
      List<Goal>? goals, String? userId) async {
    try {
      final cs = CurrencyService();
      await cs.ensureInitialized();
      final now = DateTime.now();
      final data = <String, Object>{};

      if (txs != null) {
        data.addAll(computeTransactionData(txs, budgets ?? const [], now, cs.formatAmountCompact));
      }
      if (goals != null) data.addAll(computeGoalData(goals, now, cs.formatAmountCompact));
      if (budgets != null) data.addAll(computeRingData(budgets));
      if (userId != null) {
        final recurring = await RecurringTransactionService()
            .getUserRecurringTransactions(userId);
        data.addAll(computeBillData(recurring, now, cs.formatAmountCompact));
      }

      for (final e in data.entries) {
        final v = e.value;
        if (v is int) {
          await HomeWidget.saveWidgetData<int>(e.key, v);
        } else {
          await HomeWidget.saveWidgetData<String>(e.key, v.toString());
        }
      }
      for (final p in _providers) {
        await HomeWidget.updateWidget(name: p, androidName: p);
      }
    } catch (e) {
      debugPrint('Error refreshing widgets: $e');
    }
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @visibleForTesting
  static Map<String, Object> computeTransactionData(List<Transaction> txs,
      List<Budget> budgets, DateTime now, String Function(double) fmt) {
    final today = _day(now);
    final monthStart = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;
    final expenses = txs.where((t) => t.isExpense).toList();
    final monthTx = txs.where((t) => !t.date.isBefore(monthStart)).toList();
    final monthIn = monthTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final monthOut = monthTx.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final allIn = txs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final allOut = expenses.fold(0.0, (s, t) => s + t.amount);
    final monthPct = (now.day * 100 / daysInMonth).round();

    // Safe to spend: what's left in current budgets (or this month's net
    // when there are none), spread over the days left.
    final current = budgets.where((b) => b.isCurrent).toList();
    final double left, usedPct;
    if (current.isNotEmpty) {
      final total = current.fold(0.0, (s, b) => s + b.totalAvailable);
      final spent = current.fold(0.0, (s, b) => s + b.spent);
      left = total - spent;
      usedPct = total > 0 ? spent * 100 / total : 100;
    } else {
      left = monthIn - monthOut;
      usedPct = monthIn > 0 ? monthOut * 100 / monthIn : (monthOut > 0 ? 100 : 0);
    }
    final level = left < 0 ? 2 : (usedPct > monthPct + 10 ? 1 : 0);

    // Spending per day, keyed by date.
    final byDay = <DateTime, double>{};
    for (final t in expenses) {
      final d = _day(t.date);
      byDay[d] = (byDay[d] ?? 0) + t.amount;
    }

    // Pulse: Mon..Sun of this week vs the same span last week.
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final week = List.generate(7, (i) => byDay[weekStart.add(Duration(days: i))] ?? 0.0);
    final thisWeek = week.take(now.weekday).fold(0.0, (s, v) => s + v);
    final lastWeek = List.generate(now.weekday,
            (i) => byDay[weekStart.subtract(Duration(days: 7 - i))] ?? 0.0)
        .fold(0.0, (s, v) => s + v);
    final change = lastWeek > 0 ? ((thisWeek - lastWeek) * 100 / lastWeek).round() : 0;

    // Category shares this month.
    final cats = <String, double>{};
    for (final t in monthTx.where((t) => t.isExpense)) {
      cats[t.category] = (cats[t.category] ?? 0) + t.amount;
    }
    final ranked = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String share(int i) => i < ranked.length && monthOut > 0
        ? (ranked[i].value * 100 / monthOut).round().toString()
        : '0';

    // Quick add shortcuts: most used expense categories, last 30 days.
    final counts = <String, int>{};
    for (final t in expenses.where((t) => t.date.isAfter(now.subtract(const Duration(days: 30))))) {
      counts[t.category] = (counts[t.category] ?? 0) + 1;
    }
    final top = (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => e.key)
        .followedBy(['Food & Dining', 'Transportation'])
        .toSet()
        .take(2)
        .toList();

    // No-spend streak: days back from yesterday (today counts if clean)
    // with no non-essential expense.
    final spendDays = expenses
        .where((t) => !t.isEssential && !_essential.contains(t.category))
        .map((t) => _day(t.date))
        .toSet();
    final firstDay = txs.isEmpty
        ? today
        : txs.map((t) => _day(t.date)).reduce((a, b) => a.isBefore(b) ? a : b);
    var streak = 0;
    for (var d = today; !d.isBefore(firstDay) && !spendDays.contains(d);
        d = d.subtract(const Duration(days: 1))) {
      streak++;
    }

    return {
      'safe_amount': fmt(left > 0 ? left / daysLeft : 0),
      'safe_level': level,
      'safe_status': const ['On track', 'Over pace', 'Over budget'][level],
      'safe_days_left': daysLeft,
      'month_progress': monthPct,
      'qa_cat1': top[0],
      'qa_cat2': top[1],
      'pulse_total': fmt(thisWeek),
      'pulse_change': lastWeek == 0
          ? 'First week'
          : '${change <= 0 ? '↓' : '↑'} ${change.abs()}% vs last',
      'pulse_up': change > 0 ? 1 : 0,
      'pulse_days': week.map((v) => v.toStringAsFixed(2)).join(','),
      'pulse_today': now.weekday - 1,
      'heat_month': const [
        'January', 'February', 'March', 'April', 'May', 'June', 'July',
        'August', 'September', 'October', 'November', 'December'
      ][now.month - 1],
      'heat_values': List.generate(daysInMonth,
          (i) => (byDay[DateTime(now.year, now.month, i + 1)] ?? 0).toStringAsFixed(2)).join(','),
      'heat_first_weekday': monthStart.weekday - 1,
      'heat_today': now.day,
      'streak_days': streak,
      'glance_balance': fmt(allIn - allOut),
      'glance_in': '+${fmt(monthIn)}',
      'glance_out': '−${fmt(monthOut)}',
      'top_cat': ranked.isEmpty ? 'Nothing yet' : ranked.first.key,
      'top_pct': ranked.isEmpty ? '–' : '${share(0)}%',
      'top_detail': ranked.isEmpty
          ? 'No spending this month'
          : '${fmt(ranked.first.value)} of ${fmt(monthOut)}',
      'top_shares': [share(0), share(1), share(2)].join(','),
    };
  }

  @visibleForTesting
  static Map<String, Object> computeRingData(List<Budget> budgets) {
    final current = budgets.where((b) => b.isCurrent).toList()
      ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
    final picked = current.take(3).toList();
    return {
      'ring_names': picked.map((b) => b.name.isEmpty ? b.category : b.name).join('|'),
      'ring_pcts': picked.map((b) => b.progressPercentage.round()).join(','),
    };
  }

  @visibleForTesting
  static Map<String, Object> computeGoalData(
      List<Goal> goals, DateTime now, String Function(double) fmt) {
    final active = goals.where((g) => g.status == GoalStatus.active).toList()
      ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
    if (active.isEmpty) {
      return {
        'goal_name': 'No goal yet',
        'goal_pct': 0,
        'goal_amounts': 'Tap to set one',
        'goal_eta': '',
      };
    }
    final g = active.first;
    // ponytail: ETA assumes a steady pace since the goal was created;
    // use real contribution history if goals start tracking it.
    final days = now.difference(g.createdAt).inDays.clamp(1, 100000);
    final perDay = g.currentAmount / days;
    final String eta;
    if (g.remaining <= 0) {
      eta = 'Reached';
    } else if (perDay <= 0) {
      eta = 'Not started';
    } else {
      final d = (g.remaining / perDay).ceil();
      eta = d < 14 ? '~$d days to go' : '~${(d / 7).round()} weeks to go';
    }
    return {
      'goal_name': g.name,
      'goal_pct': g.progressPercentage.round(),
      'goal_amounts': '${fmt(g.currentAmount)} of ${fmt(g.targetAmount)}',
      'goal_eta': eta,
    };
  }

  @visibleForTesting
  static Map<String, Object> computeBillData(
      List<RecurringTransaction> recurring, DateTime now, String Function(double) fmt) {
    final today = _day(now);
    final bills = recurring
        .where((r) => r.isActive && r.type == TransactionType.expense)
        .toList()
      ..sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));
    final weekTotal = bills
        .where((r) => _day(r.nextRunAt).difference(today).inDays < 7)
        .fold(0.0, (s, r) => s + r.amount);
    String when(DateTime d) {
      final n = _day(d).difference(today).inDays;
      if (n < 0) return 'Overdue';
      if (n == 0) return 'Today';
      if (n == 1) return 'Tomorrow';
      return 'in $n days';
    }

    final out = <String, Object>{
      'bills_count': bills.length.clamp(0, 3),
      'bills_week_total': '${fmt(weekTotal)} this week',
    };
    for (var i = 0; i < 3; i++) {
      final b = i < bills.length ? bills[i] : null;
      out['bill${i}_name'] = b?.title ?? '';
      out['bill${i}_when'] = b == null ? '' : when(b.nextRunAt);
      out['bill${i}_amount'] = b == null ? '' : fmt(b.amount);
      out['bill${i}_category'] = b?.category ?? '';
    }
    return out;
  }
}
