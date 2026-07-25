import 'package:equatable/equatable.dart';

import 'transaction_model.dart';

enum RecurringTransactionFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

enum RecurringTransactionStatus {
  active,
  paused,
  ended,
}

class RecurringTransaction extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final String? budgetId;
  final bool isEssential;
  final RecurringTransactionFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextRunAt;
  final DateTime? lastRunAt;
  final bool autoCreate;
  final RecurringTransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const RecurringTransaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    this.budgetId,
    this.isEssential = false,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextRunAt,
    this.lastRunAt,
    this.autoCreate = true,
    this.status = RecurringTransactionStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  bool get isActive => status == RecurringTransactionStatus.active;

  RecurringTransaction copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    String? budgetId,
    bool? isEssential,
    RecurringTransactionFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    bool? autoCreate,
    RecurringTransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      budgetId: budgetId ?? this.budgetId,
      isEssential: isEssential ?? this.isEssential,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      autoCreate: autoCreate ?? this.autoCreate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'isEssential': isEssential,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextRunAt': nextRunAt.toIso8601String(),
      'lastRunAt': lastRunAt?.toIso8601String(),
      'autoCreate': autoCreate,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: TransactionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: json['category'] as String? ?? 'Other',
      budgetId: json['budgetId'] as String?,
      isEssential: json['isEssential'] as bool? ?? false,
      frequency: RecurringTransactionFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
        orElse: () => RecurringTransactionFrequency.monthly,
      ),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      nextRunAt: json['nextRunAt'] != null
          ? DateTime.parse(json['nextRunAt'] as String)
          : DateTime.now(),
      lastRunAt: json['lastRunAt'] != null
          ? DateTime.parse(json['lastRunAt'] as String)
          : null,
      autoCreate: json['autoCreate'] as bool? ?? true,
      status: RecurringTransactionStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => RecurringTransactionStatus.active,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? const {}),
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
        isEssential,
        frequency,
        startDate,
        endDate,
        nextRunAt,
        lastRunAt,
        autoCreate,
        status,
        createdAt,
        updatedAt,
        metadata,
      ];
}

extension RecurringTransactionFrequencyLabel on RecurringTransactionFrequency {
  String get label => switch (this) {
        RecurringTransactionFrequency.daily => 'Daily',
        RecurringTransactionFrequency.weekly => 'Weekly',
        RecurringTransactionFrequency.monthly => 'Monthly',
        RecurringTransactionFrequency.yearly => 'Yearly',
      };
}
