import '../models/budget_model.dart';
import '../models/financial_snapshot.dart';
import '../models/goal_model.dart';
import 'planning_insights_service.dart';

class FinancialInsight {
  final String title;
  final String message;
  final InsightTone tone;
  final String actionLabel;
  final FinancialInsightAction action;

  const FinancialInsight({
    required this.title,
    required this.message,
    required this.tone,
    required this.actionLabel,
    required this.action,
  });
}

enum InsightTone { positive, attention, neutral }

enum FinancialInsightAction { budgets, goals, transactions }

/// Produces short, explainable recommendations from local financial data.
/// No remote model or sensitive data leaves the device.
class FinancialInsightsService {
  final PlanningInsightsService _planning = PlanningInsightsService();

  List<FinancialInsight> generate({
    required FinancialSnapshot snapshot,
    required List<Budget> budgets,
    required List<Goal> goals,
  }) {
    final insights = <FinancialInsight>[];
    final forecasts = _planning.forecastBudgets(budgets);
    final atRisk = forecasts.where((forecast) => forecast.likelyOverBudget);

    if (atRisk.isNotEmpty) {
      final forecast = atRisk.first;
      insights.add(FinancialInsight(
        title: 'Protect your ${forecast.budget.name} budget',
        message:
            'At your current pace, it may exceed its limit by ${forecast.projectedOverage.toStringAsFixed(0)}. Slow spending here first.',
        tone: InsightTone.attention,
        actionLabel: 'Review budget',
        action: FinancialInsightAction.budgets,
      ));
    }

    if (snapshot.savingsRate != null && snapshot.savingsRate! >= 20) {
      insights.add(const FinancialInsight(
        title: 'Strong savings pace',
        message:
            'You are keeping at least 20% of this month\'s income. Consider directing the surplus toward a priority goal.',
        tone: InsightTone.positive,
        actionLabel: 'View goals',
        action: FinancialInsightAction.goals,
      ));
    } else if (snapshot.monthlyExpenses > snapshot.monthlyIncome &&
        snapshot.monthlyIncome > 0) {
      insights.add(const FinancialInsight(
        title: 'This month is running negative',
        message:
            'Expenses are above income so far. Review the largest recent categories before adding new commitments.',
        tone: InsightTone.attention,
        actionLabel: 'Review spending',
        action: FinancialInsightAction.transactions,
      ));
    }

    final overdueGoals = goals.where((goal) => goal.isOverdue).length;
    if (overdueGoals > 0) {
      insights.add(FinancialInsight(
        title:
            'Revisit $overdueGoals overdue goal${overdueGoals == 1 ? '' : 's'}',
        message:
            'Adjust the target date or monthly contribution so your plan reflects reality.',
        tone: InsightTone.attention,
        actionLabel: 'Review goals',
        action: FinancialInsightAction.goals,
      ));
    } else if (snapshot.activeGoalCount == 0) {
      insights.add(const FinancialInsight(
        title: 'Give your surplus a purpose',
        message:
            'Create a savings goal so Flux can show the monthly amount needed to reach it.',
        tone: InsightTone.neutral,
        actionLabel: 'Create a goal',
        action: FinancialInsightAction.goals,
      ));
    }

    if (insights.isEmpty) {
      insights.add(const FinancialInsight(
        title: 'Keep building your picture',
        message:
            'A few more days of transactions will make your spending forecasts and recommendations more accurate.',
        tone: InsightTone.neutral,
        actionLabel: 'Add transaction',
        action: FinancialInsightAction.transactions,
      ));
    }
    return insights.take(3).toList();
  }
}
