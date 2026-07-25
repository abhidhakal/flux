import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:equatable/equatable.dart';

enum TransactionType {
  income,
  expense
}

/// Represents a financial transaction, either income or expense.
class Transaction extends Equatable {
  static const Object _unset = Object();

  final String id;
  final String userId;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final String category; // Direct category name - no complex mapping
  final String? budgetId; // Optional budget assignment
  final bool isActive;
  final bool
      isEssential; // User-defined essential status (Needs vs Wants) - NEW FIELD
  final DateTime date;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const Transaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    this.budgetId,
    this.isActive = true,
    this.isEssential = false,
    required this.date,
    required this.createdAt,
    this.metadata = const {},
  });

  // Helper getters for easy access
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  Transaction copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    Object? budgetId = _unset,
    bool? isActive,
    bool? isEssential,
    DateTime? date,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      budgetId:
          identical(budgetId, _unset) ? this.budgetId : budgetId as String?,
      isActive: isActive ?? this.isActive,
      isEssential: isEssential ?? this.isEssential,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category,
      'budgetId': budgetId,
      'isActive': isActive,
      'isEssential': isEssential,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Transaction',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: json['category'] as String? ?? 'Other',
      budgetId: json['budgetId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isEssential: json['isEssential'] as bool? ?? false,
      date: _parseDateTime(json['date']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['date']),
      metadata: _parseMetadata(json['metadata']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is firestore.Timestamp) {
      return value.toDate();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  static Map<String, dynamic> _parseMetadata(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        amount,
        type,
        category,
        budgetId,
        isActive,
        isEssential,
        date,
        createdAt,
        metadata,
      ];
}

extension TransactionListTotals on List<Transaction> {
  double totalIncome() =>
      where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

  double totalExpenses() =>
      where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

  double get netBalance => totalIncome() - totalExpenses();
}
