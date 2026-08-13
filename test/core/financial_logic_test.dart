import 'package:flutter_test/flutter_test.dart';
import 'package:flux/core/models/budget_model.dart';
import 'package:flux/core/models/financial_snapshot.dart';
import 'package:flux/core/models/transaction_model.dart';
import 'package:flux/core/services/financial_insights_service.dart';
import 'package:flux/core/services/planning_insights_service.dart';

void main() {
  final now = DateTime(2026, 8, 13);

  Transaction transaction({
    required String id,
    required double amount,
    required TransactionType type,
  }) {
    return Transaction(
      id: id,
      userId: 'user-1',
      title: id,
      description: '',
      amount: amount,
      type: type,
      category: 'Other',
      date: now,
      createdAt: now,
    );
  }

  test('financial snapshot calculates net flow and savings rate', () {
    final snapshot = FinancialSnapshot.fromData(
      transactions: [
        transaction(id: 'income', amount: 2000, type: TransactionType.income),
        transaction(id: 'expense', amount: 500, type: TransactionType.expense),
      ],
      budgets: const [],
      goals: const [],
      now: now,
    );

    expect(snapshot.monthlyNet, 1500);
    expect(snapshot.savingsRate, 75);
  });

  test('budget forecast identifies likely overage', () {
    final budget = Budget(
      id: 'food',
      userId: 'user-1',
      name: 'Food',
      amount: 100,
      spent: 80,
      category: 'Food',
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      createdAt: now,
    );
    final forecast = PlanningInsightsService().forecastBudgets(
      [budget],
      now: DateTime(2026, 8, 20),
    ).single;

    expect(forecast.likelyOverBudget, isTrue);
    expect(forecast.projectedOverage, greaterThan(0));
  });

  test('financial insights returns an explainable savings insight', () {
    final snapshot = FinancialSnapshot.fromData(
      transactions: [
        transaction(id: 'income', amount: 2000, type: TransactionType.income),
        transaction(id: 'expense', amount: 500, type: TransactionType.expense),
      ],
      budgets: const [],
      goals: const [],
      now: now,
    );

    final insights = FinancialInsightsService().generate(
      snapshot: snapshot,
      budgets: const [],
      goals: const [],
    );
    expect(insights, isNotEmpty);
    expect(
        insights.any((insight) => insight.title.contains('savings')), isTrue);
  });
}
