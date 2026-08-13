import 'package:flutter_test/flutter_test.dart';
import 'package:flux/core/models/recurring_transaction_model.dart';
import 'package:flux/core/models/transaction_model.dart';
import 'package:flux/core/services/recurring_transaction_service.dart';

void main() {
  final service = RecurringTransactionService();

  test('calculates monthly dates without overflowing short months', () {
    final next = service.calculateInitialNextRunAt(
      DateTime(2024, 1, 31),
      RecurringTransactionFrequency.monthly,
      fromDate: DateTime(2024, 1, 1),
    );

    expect(next, DateTime(2024, 2, 29));
  });

  test('advances the initial date beyond the current period', () {
    final next = service.calculateInitialNextRunAt(
      DateTime(2026, 8, 1),
      RecurringTransactionFrequency.monthly,
      fromDate: DateTime(2026, 8, 13),
    );

    expect(next, DateTime(2026, 9, 1));
  });

  test('recurring transactions preserve fields through serialization', () {
    final original = RecurringTransaction(
      id: 'rent',
      userId: 'user-1',
      title: 'Rent',
      description: 'Apartment',
      amount: 1200,
      type: TransactionType.expense,
      category: 'Housing',
      frequency: RecurringTransactionFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      nextRunAt: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 8, 13),
      metadata: const {'source': 'test'},
    );

    expect(RecurringTransaction.fromJson(original.toJson()), original);
  });
}
