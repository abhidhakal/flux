import 'package:flutter_test/flutter_test.dart';
import 'package:flux/core/models/budget_model.dart';
import 'package:flux/core/services/adaptive_budget_service.dart';

void main() {
  final service = AdaptiveBudgetService();
  final start = DateTime(2026, 8, 1);

  Budget budget({double spent = 0}) => Budget(
        id: 'food',
        userId: 'user-1',
        name: 'Food',
        amount: 300,
        spent: spent,
        category: 'Food',
        period: BudgetPeriod.monthly,
        startDate: start,
        endDate: DateTime(2026, 8, 31, 23, 59),
        createdAt: start,
      );

  test('calculates a daily and weekly safe spending amount', () {
    final insight = service.analyze(
      budget(spent: 100),
      now: DateTime(2026, 8, 11),
    );

    expect(insight.dailySafeSpend, closeTo(200 / 21, 0.01));
    expect(insight.weeklySafeSpend, closeTo(200 / 21 * 7, 0.01));
  });

  test('flags a budget that is spending faster than its timeline', () {
    final insight = service.analyze(
      budget(spent: 180),
      now: DateTime(2026, 8, 6),
    );

    expect(insight.status, BudgetPaceStatus.atRisk);
    expect(insight.needsAttention, isTrue);
  });

  test('uses a custom weekly target while respecting remaining room', () {
    final insight = service.analyze(
      budget(spent: 100).copyWith(weeklyTarget: 40),
      now: DateTime(2026, 8, 11),
    );

    expect(insight.weeklySafeSpend, 40);
  });

  test('budget serialization preserves adaptive settings', () {
    final original = budget(spent: 100).copyWith(
      weeklyTarget: 75,
      temporaryAdjustment: 50,
      adjustmentExpiresAt: DateTime(2026, 8, 20),
    );

    expect(Budget.fromJson(original.toJson()), original);
  });
}
