import 'budget_model.dart';
import 'goal_model.dart';
import 'transaction_model.dart';

/// A small, presentation-ready summary of the user's current financial state.
///
/// Keeping these calculations out of widgets gives the dashboard, onboarding,
/// notifications, and future offline cache one consistent source of truth.
class FinancialSnapshot {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double activeBudgetRemaining;
  final double activeBudgetProgress;
  final double goalProgress;
  final int activeGoalCount;

  const FinancialSnapshot({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.activeBudgetRemaining,
    required this.activeBudgetProgress,
    required this.goalProgress,
    required this.activeGoalCount,
  });

  double get monthlyNet => monthlyIncome - monthlyExpenses;

  double? get savingsRate => monthlyIncome <= 0
      ? null
      : ((monthlyIncome - monthlyExpenses) / monthlyIncome) * 100;

  factory FinancialSnapshot.fromData({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Goal> goals,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final monthStart = DateTime(reference.year, reference.month);
    final nextMonthStart = DateTime(reference.year, reference.month + 1);
    final monthlyTransactions = transactions.where(
      (transaction) =>
          !transaction.date.isBefore(monthStart) &&
          transaction.date.isBefore(nextMonthStart),
    );

    final activeBudgets = budgets.where((budget) => budget.isCurrent).toList();
    final availableBudget = activeBudgets.fold<double>(
      0,
      (total, budget) => total + budget.totalAvailable,
    );
    final spentBudget = activeBudgets.fold<double>(
      0,
      (total, budget) => total + budget.spent,
    );
    final activeGoals = goals.where((goal) => goal.status == GoalStatus.active);
    final goalTarget = activeGoals.fold<double>(
      0,
      (total, goal) => total + goal.targetAmount,
    );
    final goalCurrent = activeGoals.fold<double>(
      0,
      (total, goal) => total + goal.currentAmount,
    );

    return FinancialSnapshot(
      totalIncome: transactions.totalIncome(),
      totalExpenses: transactions.totalExpenses(),
      balance: transactions.netBalance,
      monthlyIncome: monthlyTransactions
          .where((transaction) => transaction.isIncome)
          .fold(0, (total, transaction) => total + transaction.amount),
      monthlyExpenses: monthlyTransactions
          .where((transaction) => transaction.isExpense)
          .fold(0, (total, transaction) => total + transaction.amount),
      activeBudgetRemaining: availableBudget - spentBudget,
      activeBudgetProgress:
          availableBudget <= 0 ? 0 : (spentBudget / availableBudget) * 100,
      goalProgress: goalTarget <= 0 ? 0 : (goalCurrent / goalTarget) * 100,
      activeGoalCount: activeGoals.length,
    );
  }
}
