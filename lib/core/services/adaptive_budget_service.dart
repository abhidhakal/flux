import '../models/budget_model.dart';

enum BudgetPaceStatus { ahead, onTrack, atRisk, over }

class AdaptiveBudgetInsight {
  final Budget budget;
  final int daysRemaining;
  final double dailySafeSpend;
  final double weeklySafeSpend;
  final double expectedSpendPercentage;
  final BudgetPaceStatus status;

  const AdaptiveBudgetInsight({
    required this.budget,
    required this.daysRemaining,
    required this.dailySafeSpend,
    required this.weeklySafeSpend,
    required this.expectedSpendPercentage,
    required this.status,
  });

  bool get needsAttention =>
      status == BudgetPaceStatus.atRisk || status == BudgetPaceStatus.over;

  String get recommendation {
    switch (status) {
      case BudgetPaceStatus.over:
        return 'Pause non-essential ${budget.category.toLowerCase()} spending until the next period.';
      case BudgetPaceStatus.atRisk:
        return 'Keep ${budget.category.toLowerCase()} spending under the weekly limit to recover your pace.';
      case BudgetPaceStatus.ahead:
        return 'You have room in this budget. Keep the surplus available for the rest of the period.';
      case BudgetPaceStatus.onTrack:
        return 'Your spending pace is healthy for this period.';
    }
  }
}

/// Turns a static budget into a forward-looking spending plan without
/// requiring bank connections or sending financial data off-device.
class AdaptiveBudgetService {
  AdaptiveBudgetInsight analyze(Budget budget, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final totalDays = budget.endDate.difference(budget.startDate).inDays + 1;
    final elapsedDays = reference
        .difference(budget.startDate)
        .inDays
        .clamp(1, totalDays < 1 ? 1 : totalDays);
    final daysRemaining = budget.endDate.difference(reference).inDays + 1;
    final remaining = budget.remaining.clamp(0, double.infinity).toDouble();
    final dailySafeSpend = daysRemaining <= 0 ? 0.0 : remaining / daysRemaining;
    final weeklySafeSpend = budget.hasWeeklyTarget
        ? budget.resolvedWeeklyTarget.clamp(0, dailySafeSpend * 7).toDouble()
        : dailySafeSpend * 7;
    final expectedSpendPercentage =
        totalDays <= 0 ? 100.0 : elapsedDays / totalDays * 100;
    final actualPercentage = budget.progressPercentage;

    final status = budget.isOverBudget
        ? BudgetPaceStatus.over
        : actualPercentage > expectedSpendPercentage + 10
            ? BudgetPaceStatus.atRisk
            : actualPercentage < expectedSpendPercentage - 10
                ? BudgetPaceStatus.ahead
                : BudgetPaceStatus.onTrack;

    return AdaptiveBudgetInsight(
      budget: budget,
      daysRemaining: daysRemaining.clamp(0, 100000).toInt(),
      dailySafeSpend: dailySafeSpend,
      weeklySafeSpend: weeklySafeSpend,
      expectedSpendPercentage: expectedSpendPercentage,
      status: status,
    );
  }

  List<AdaptiveBudgetInsight> analyzeAll(
    List<Budget> budgets, {
    DateTime? now,
  }) {
    return budgets
        .where((budget) => budget.isCurrent)
        .map((budget) => analyze(budget, now: now))
        .toList()
      ..sort((a, b) {
        final status = b.status.index.compareTo(a.status.index);
        return status != 0
            ? status
            : b.budget.progressPercentage
                .compareTo(a.budget.progressPercentage);
      });
  }
}
