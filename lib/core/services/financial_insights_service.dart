import '../models/budget_model.dart';
import '../models/financial_snapshot.dart';
import '../models/goal_model.dart';
import 'currency_service.dart';
import 'planning_insights_service.dart';

class FinancialInsight {
  final String title;

  /// A plain-language explanation of the data signal that triggered this insight.
  final String basedOn;
  final String message;
  final InsightTone tone;
  final String actionLabel;
  final FinancialInsightAction action;

  const FinancialInsight({
    required this.title,
    required this.basedOn,
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
        basedOn: 'Based on your projected spending pace',
        message:
            'At your current pace, it may exceed its limit by ${CurrencyService().formatAmountCompact(forecast.projectedOverage)}. Acting early gives you more room to adjust.',
        tone: InsightTone.attention,
        actionLabel: 'Review budget',
        action: FinancialInsightAction.budgets,
      ));
    }

    if (snapshot.savingsRate != null && snapshot.savingsRate! >= 20) {
      insights.add(const FinancialInsight(
        title: 'Strong savings pace',
        basedOn: 'Based on this month\'s income and spending',
        message:
            'You are keeping at least 20% of this month\'s income. Directing part of that surplus toward a priority goal can make it tangible.',
        tone: InsightTone.positive,
        actionLabel: 'View goals',
        action: FinancialInsightAction.goals,
      ));
    } else if (snapshot.monthlyExpenses > snapshot.monthlyIncome &&
        snapshot.monthlyIncome > 0) {
      insights.add(const FinancialInsight(
        title: 'This month is running negative',
        basedOn: 'Based on this month\'s income and spending',
        message:
            'Expenses are above income so far. Reviewing the largest recent categories can help you find the quickest adjustment.',
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
        basedOn: 'Based on your goal dates and progress',
        message:
            'Adjust the target date or monthly contribution so the plan reflects reality instead of becoming background noise.',
        tone: InsightTone.attention,
        actionLabel: 'Review goals',
        action: FinancialInsightAction.goals,
      ));
    } else if (snapshot.activeGoalCount == 0) {
      insights.add(const FinancialInsight(
        title: 'Give your surplus a purpose',
        basedOn: 'Based on your current goals and monthly surplus',
        message:
            'Create a savings goal so Flux can turn your available surplus into a clear monthly target.',
        tone: InsightTone.neutral,
        actionLabel: 'Create a goal',
        action: FinancialInsightAction.goals,
      ));
    }

    if (insights.isEmpty) {
      insights.add(const FinancialInsight(
        title: 'Keep building your picture',
        basedOn: 'Based on the amount of recent activity',
        message:
            'A few more days of transactions will make your spending forecasts and recommendations more useful.',
        tone: InsightTone.neutral,
        actionLabel: 'Add transaction',
        action: FinancialInsightAction.transactions,
      ));
    }
    return insights.take(3).toList();
  }
}
