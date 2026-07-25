import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import 'transaction_service.dart';

class RecurringTransactionService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final TransactionService _transactionService;
  final Uuid _uuid = const Uuid();

  RecurringTransactionService({TransactionService? transactionService})
      : _transactionService = transactionService ?? TransactionService();

  Future<void> addRecurringTransaction(RecurringTransaction recurring) async {
    final recurringId = recurring.id.isEmpty ? _uuid.v4() : recurring.id;
    final recurringToSave = recurring.copyWith(
      id: recurringId,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('recurring_transactions')
        .doc(recurringId)
        .set(recurringToSave.toJson());
  }

  Future<List<RecurringTransaction>> getUserRecurringTransactions(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('recurring_transactions')
          .where('userId', isEqualTo: userId)
          .get();

      final recurringTransactions = querySnapshot.docs
          .map((doc) => RecurringTransaction.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));

      return recurringTransactions;
    } catch (e) {
      debugPrint('Failed to load recurring transactions: $e');
      return [];
    }
  }

  Future<void> updateRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
    try {
      await _firestore
          .collection('recurring_transactions')
          .doc(recurring.id)
          .set(
            recurring
                .copyWith(
                  updatedAt: DateTime.now(),
                )
                .toJson(),
          );
    } catch (e) {
      debugPrint('Failed to update recurring transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteRecurringTransaction(String recurringId) async {
    try {
      await _firestore
          .collection('recurring_transactions')
          .doc(recurringId)
          .delete();
    } catch (e) {
      debugPrint('Failed to delete recurring transaction: $e');
      rethrow;
    }
  }

  Future<void> processDueTransactions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('recurring_transactions')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return;
      }

      final now = DateTime.now();
      for (final doc in querySnapshot.docs) {
        var recurring = RecurringTransaction.fromJson(doc.data());
        if (!recurring.isActive || !recurring.autoCreate) {
          continue;
        }

        var hasChanges = false;
        while (!recurring.nextRunAt.isAfter(now)) {
          if (recurring.endDate != null &&
              recurring.nextRunAt.isAfter(recurring.endDate!)) {
            recurring = recurring.copyWith(
              status: RecurringTransactionStatus.ended,
              updatedAt: now,
            );
            hasChanges = true;
            break;
          }

          final occurrenceDate = recurring.nextRunAt;
          final occurrenceId =
              _buildOccurrenceTransactionId(recurring.id, occurrenceDate);
          final existing = await _firestore
              .collection('transactions')
              .doc(occurrenceId)
              .get();

          if (!existing.exists) {
            final transaction = Transaction(
              id: occurrenceId,
              userId: recurring.userId,
              title: recurring.title,
              description: recurring.description,
              amount: recurring.amount,
              type: recurring.type,
              category: recurring.category,
              budgetId: recurring.type == TransactionType.expense
                  ? recurring.budgetId
                  : null,
              isEssential: recurring.type == TransactionType.expense
                  ? recurring.isEssential
                  : false,
              date: occurrenceDate,
              createdAt: now,
              metadata: {
                ...recurring.metadata,
                'source': 'recurring',
                'recurringId': recurring.id,
                'occurrenceDate': _dateOnlyIso(occurrenceDate),
              },
            );
            await _transactionService.addTransaction(transaction);
          }

          final nextRunAt =
              _calculateNextRunAt(occurrenceDate, recurring.frequency);
          final hasEnded = recurring.endDate != null &&
              nextRunAt.isAfter(recurring.endDate!);
          recurring = recurring.copyWith(
            lastRunAt: occurrenceDate,
            nextRunAt: nextRunAt,
            status: hasEnded
                ? RecurringTransactionStatus.ended
                : RecurringTransactionStatus.active,
            updatedAt: now,
          );
          hasChanges = true;

          if (hasEnded) {
            break;
          }
        }

        if (hasChanges) {
          await _firestore
              .collection('recurring_transactions')
              .doc(recurring.id)
              .set(recurring.toJson());
        }
      }
    } catch (e) {
      debugPrint('Recurring transaction processing failed: $e');
    }
  }

  DateTime calculateInitialNextRunAt(
    DateTime occurrenceDate,
    RecurringTransactionFrequency frequency, {
    DateTime? fromDate,
  }) {
    final threshold = fromDate ?? DateTime.now();
    var nextRunAt = _calculateNextRunAt(occurrenceDate, frequency);
    while (!nextRunAt.isAfter(threshold)) {
      nextRunAt = _calculateNextRunAt(nextRunAt, frequency);
    }
    return nextRunAt;
  }

  DateTime _calculateNextRunAt(
    DateTime current,
    RecurringTransactionFrequency frequency,
  ) {
    return switch (frequency) {
      RecurringTransactionFrequency.daily =>
        current.add(const Duration(days: 1)),
      RecurringTransactionFrequency.weekly =>
        current.add(const Duration(days: 7)),
      RecurringTransactionFrequency.monthly => _addMonthsClamped(current, 1),
      RecurringTransactionFrequency.yearly => DateTime(
          current.year + 1,
          current.month,
          _clampDay(current.year + 1, current.month, current.day),
          current.hour,
          current.minute,
          current.second,
          current.millisecond,
          current.microsecond,
        ),
    };
  }

  DateTime _addMonthsClamped(DateTime date, int monthOffset) {
    final totalMonths = date.month + monthOffset;
    final year = date.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;
    final day = _clampDay(year, month, date.day);
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  int _clampDay(int year, int month, int day) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    return day > lastDayOfMonth ? lastDayOfMonth : day;
  }

  String _buildOccurrenceTransactionId(String recurringId, DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'recurring_${recurringId}_${date.year}$month$day';
  }

  String _dateOnlyIso(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
