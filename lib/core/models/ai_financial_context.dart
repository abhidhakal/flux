import 'budget_model.dart';
import 'goal_model.dart';
import 'transaction_model.dart';

/// The only financial data shape allowed to cross the future AI boundary.
/// It contains aggregates, never raw transactions or identifying fields.
class AiFinancialContext {
  final String currencyCode;
  final String currencySymbol;
  final int currencyDecimalPlaces;
  final double income;
  final double expenses;
  final double net;
  final double? savingsRate;
  final Map<String, double> categoryTotals;
  final int activeBudgetCount;
  final int atRiskBudgetCount;
  final int activeGoalCount;
  final int overdueGoalCount;

  const AiFinancialContext({
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDecimalPlaces,
    required this.income,
    required this.expenses,
    required this.net,
    required this.savingsRate,
    required this.categoryTotals,
    required this.activeBudgetCount,
    required this.atRiskBudgetCount,
    required this.activeGoalCount,
    required this.overdueGoalCount,
  });

  factory AiFinancialContext.fromData({
    required String currencyCode,
    required String currencySymbol,
    required int currencyDecimalPlaces,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Goal> goals,
  }) {
    final income = transactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final expenses = transactions
        .where((transaction) => transaction.isExpense)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final categoryTotals = <String, double>{};
    for (final transaction in transactions.where((item) => item.isExpense)) {
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }

    final activeBudgets = budgets.where((budget) => budget.isActive).toList();
    final activeGoals =
        goals.where((goal) => goal.status == GoalStatus.active).toList();

    return AiFinancialContext(
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      currencyDecimalPlaces: currencyDecimalPlaces,
      income: income,
      expenses: expenses,
      net: income - expenses,
      savingsRate: income <= 0 ? null : ((income - expenses) / income) * 100,
      categoryTotals: Map.unmodifiable(categoryTotals),
      activeBudgetCount: activeBudgets.length,
      atRiskBudgetCount:
          activeBudgets.where((budget) => budget.isOverBudget).length,
      activeGoalCount: activeGoals.length,
      overdueGoalCount: activeGoals.where((goal) => goal.isOverdue).length,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 2,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'currencyDecimalPlaces': currencyDecimalPlaces,
        'income': income,
        'expenses': expenses,
        'net': net,
        'savingsRate': savingsRate,
        'categoryTotals': categoryTotals,
        'activeBudgetCount': activeBudgetCount,
        'atRiskBudgetCount': atRiskBudgetCount,
        'activeGoalCount': activeGoalCount,
        'overdueGoalCount': overdueGoalCount,
      };
}
