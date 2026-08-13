import 'package:flutter_test/flutter_test.dart';
import 'package:flux/core/models/ai_financial_context.dart';
import 'package:flux/core/models/transaction_model.dart';

void main() {
  test('AI context contains aggregates and no raw transaction fields', () {
    final now = DateTime(2026, 8, 13);
    final context = AiFinancialContext.fromData(
      currencyCode: 'NPR',
      currencySymbol: 'Rs.',
      currencyDecimalPlaces: 2,
      transactions: [
        Transaction(
          id: 'private-id',
          userId: 'private-user',
          title: 'Private title',
          description: 'Private description',
          amount: 2000,
          type: TransactionType.income,
          category: 'Salary',
          date: now,
          createdAt: now,
        ),
        Transaction(
          id: 'expense-id',
          userId: 'private-user',
          title: 'Private purchase',
          description: 'Private note',
          amount: 500,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      ],
      budgets: const [],
      goals: const [],
    );

    final payload = context.toJson();
    expect(payload['currencyCode'], 'NPR');
    expect(payload['currencySymbol'], 'Rs.');
    expect(payload['currencyDecimalPlaces'], 2);
    expect(payload['income'], 2000);
    expect(payload['expenses'], 500);
    expect(payload['categoryTotals'], {'Food': 500});
    expect(payload.containsKey('title'), isFalse);
    expect(payload.containsKey('description'), isFalse);
    expect(payload.containsKey('userId'), isFalse);
    expect(payload.containsKey('id'), isFalse);
  });
}
