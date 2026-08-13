import '../models/budget_model.dart';
import '../models/goal_model.dart';

class BudgetForecast {
  final Budget budget;
  final double projectedSpent;
  final double dailySpendRate;

  const BudgetForecast({
    required this.budget,
    required this.projectedSpent,
    required this.dailySpendRate,
  });

  bool get likelyOverBudget => projectedSpent > budget.totalAvailable;
  double get projectedOverage => projectedSpent - budget.totalAvailable;
}

class GoalFundingPlan {
  final Goal goal;
  final double monthlyAmount;
  final int monthsRemaining;

  const GoalFundingPlan({
    required this.goal,
    required this.monthlyAmount,
    required this.monthsRemaining,
  });
}

/// Deterministic planning calculations shared by budget and goal screens.
class PlanningInsightsService {
  BudgetForecast forecastBudget(Budget budget, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final totalDays = budget.endDate.difference(budget.startDate).inDays.abs();
    final elapsedDays = reference
        .difference(budget.startDate)
        .inDays
        .clamp(1, totalDays <= 0 ? 1 : totalDays);
    final dailySpendRate = budget.spent / elapsedDays;
    return BudgetForecast(
      budget: budget,
      projectedSpent: dailySpendRate * (totalDays <= 0 ? 1 : totalDays),
      dailySpendRate: dailySpendRate,
    );
  }

  List<BudgetForecast> forecastBudgets(List<Budget> budgets, {DateTime? now}) {
    return budgets
        .where((budget) => budget.isCurrent)
        .map((budget) => forecastBudget(budget, now: now))
        .toList()
      ..sort((a, b) => b.projectedOverage.compareTo(a.projectedOverage));
  }

  List<GoalFundingPlan> fundingPlans(List<Goal> goals, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return goals
        .where((goal) => goal.status == GoalStatus.active && goal.remaining > 0)
        .map((goal) {
      final months = goal.targetDate.difference(reference).inDays ~/ 30;
      final monthsRemaining = months < 1 ? 1 : months;
      return GoalFundingPlan(
        goal: goal,
        monthlyAmount: goal.remaining / monthsRemaining,
        monthsRemaining: monthsRemaining,
      );
    }).toList()
      ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
  }
}
