import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/recurring_transaction_model.dart';
import 'subscription_service.dart';

class PremiumLimitsService {
  static const int freeBudgetLimit = 3;
  static const int freeGoalLimit = 2;
  static const int freeRecurringLimit = 1;

  bool get isPremium => SubscriptionService().isPremium;

  bool canCreateBudget(List<Budget> budgets) {
    return isPremium ||
        budgets.where((budget) => budget.isActive).length < freeBudgetLimit;
  }

  bool canCreateGoal(List<Goal> goals) {
    return isPremium ||
        goals.where((goal) => goal.status == GoalStatus.active).length <
            freeGoalLimit;
  }

  bool canCreateRecurring(List<RecurringTransaction> recurringTransactions) {
    return isPremium ||
        recurringTransactions.where((item) => item.isActive).length <
            freeRecurringLimit;
  }
}
