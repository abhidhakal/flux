import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final String category; // Direct category name - no complex mapping
  final String? budgetId; // Optional budget assignment - NEW FIELD
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
    required this.date,
    required this.createdAt,
    this.metadata = const {},
  });

  // Helper getters for easy access
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  
  // For budget matching - exact category comparison
  String get categoryForBudget => category;

  Transaction copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    String? budgetId,
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
      budgetId: budgetId ?? this.budgetId,
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
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
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
        date,
        createdAt,
        metadata,
      ];
}
