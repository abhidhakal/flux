import '../models/transaction_model.dart';
import 'ai_intelligence_service.dart';

class RecurringTransactionGroup {
  final String merchant;
  final double amount;
  final List<Transaction> transactions;

  const RecurringTransactionGroup({
    required this.merchant,
    required this.amount,
    required this.transactions,
  });

  DateTime get nextLikelyDate {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.date.add(const Duration(days: 30));
  }
}

/// Local, deterministic transaction intelligence. It is deliberately
/// side-effect free so it can later run against cached or synced data.
class TransactionIntelligenceService {
  final AIIntelligenceService _ai = AIIntelligenceService();

  String normalizeMerchant(Transaction transaction) {
    final source = transaction.title.trim().isNotEmpty
        ? transaction.title
        : transaction.description;
    return source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String suggestCategory({required String title, String description = ''}) {
    return _ai.categorizeTransaction(title, description);
  }

  List<Transaction> findDuplicates(List<Transaction> transactions) {
    final duplicates = <Transaction>[];
    final seen = <String, Transaction>{};

    for (final transaction in transactions) {
      final key = [
        transaction.type.name,
        transaction.amount.toStringAsFixed(2),
        normalizeMerchant(transaction),
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      ].join('|');
      if (seen.containsKey(key)) {
        duplicates.add(transaction);
      } else {
        seen[key] = transaction;
      }
    }
    return duplicates;
  }

  List<RecurringTransactionGroup> findRecurring(
      List<Transaction> transactions) {
    final groups = <String, List<Transaction>>{};
    for (final transaction in transactions.where((item) => item.isExpense)) {
      final merchant = normalizeMerchant(transaction);
      if (merchant.isEmpty) continue;
      final key = '$merchant|${transaction.amount.toStringAsFixed(2)}';
      groups.putIfAbsent(key, () => []).add(transaction);
    }

    return groups.values
        .where((items) => items.length >= 2)
        .map(
          (items) => RecurringTransactionGroup(
            merchant: normalizeMerchant(items.first),
            amount: items.first.amount,
            transactions: [...items]..sort(
                (a, b) => b.date.compareTo(a.date),
              ),
          ),
        )
        .toList();
  }
}
