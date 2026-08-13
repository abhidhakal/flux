import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flux/core/models/transaction_model.dart';
import 'package:flux/core/services/local_data_cache_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('cache upserts and removes user-scoped transactions', () async {
    final cache = LocalDataCacheService();
    final date = DateTime(2026, 8, 13);
    final item = Transaction(
      id: 'tx-1',
      userId: 'user-1',
      title: 'Coffee',
      description: '',
      amount: 5,
      type: TransactionType.expense,
      category: 'Food',
      date: date,
      createdAt: date,
    );

    await cache.upsertTransaction('user-1', item);
    expect((await cache.loadTransactions('user-1')).single.title, 'Coffee');
    expect(await cache.loadTransactions('other-user'), isEmpty);

    await cache.removeTransaction('user-1', item.id);
    expect(await cache.loadTransactions('user-1'), isEmpty);
  });
}
