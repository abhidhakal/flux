import 'package:flutter_test/flutter_test.dart';
import 'package:flux/core/models/transaction_model.dart';
import 'package:flux/core/services/widget_service.dart';

Transaction tx(double amount, DateTime date,
        {TransactionType type = TransactionType.expense,
        String category = 'Food & Dining'}) =>
    Transaction(
      id: '$amount$date',
      userId: 'u',
      title: 't',
      description: '',
      amount: amount,
      type: type,
      category: category,
      date: date,
      createdAt: date,
    );

void main() {
  String fmt(double v) => '\$${v.toStringAsFixed(0)}';

  test('widget numbers from transactions', () {
    final now = DateTime(2026, 11, 28, 12); // Saturday, 3 days left
    final d = WidgetService.computeTransactionData([
      tx(3000, DateTime(2026, 11, 1),
          type: TransactionType.income, category: 'Salary'),
      tx(100, DateTime(2026, 11, 24)), // Tue this week
      tx(50, DateTime(2026, 11, 17)), // Tue last week
      tx(900, DateTime(2026, 11, 20), category: 'Housing'), // essential
      tx(20, DateTime(2026, 11, 25), category: 'Transportation'), // Wed
    ], const [], now, fmt);

    expect(d['safe_days_left'], 3);
    expect(d['safe_amount'], '\$643'); // (3000 - 1070) / 3
    expect(d['safe_level'], 0);
    expect(d['pulse_days'], '0.00,100.00,20.00,0.00,0.00,0.00,0.00');
    expect(d['pulse_today'], 5);
    expect(d['pulse_up'], 0); // 120 this week vs 950 same span last week
    expect(d['streak_days'], 3); // Thu, Fri, Sat clean
    expect(d['top_cat'], 'Housing');
    expect(d['heat_first_weekday'], 6); // Nov 1 2026 is a Sunday
    expect((d['heat_values'] as String).split(',').length, 30);
    expect(d['glance_out'], '−\$1070');
  });
}
