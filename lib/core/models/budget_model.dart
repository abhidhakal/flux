import 'package:equatable/equatable.dart';

enum BudgetPeriod { daily, weekly, monthly, yearly }

class Budget extends Equatable {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final BudgetPeriod period;
  final String category; // Direct category name - matches transaction.category exactly
  final DateTime startDate;
  final DateTime endDate;
  final double spent;
  final bool isActive;
  final DateTime createdAt;
  final bool enableRollover;
  final double rolloverAmount;

  const Budget({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.period,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.spent = 0.0,
    this.isActive = true,
    required this.createdAt,
    this.enableRollover = false,
    this.rolloverAmount = 0.0,
  });

  // Core budget calculations
  double get totalAvailable => amount + rolloverAmount;
  double get remaining => totalAvailable - spent;
  double get progressPercentage => totalAvailable > 0 ? (spent / totalAvailable) * 100 : 0;
  bool get isOverBudget => spent > totalAvailable;
  bool get hasRollover => rolloverAmount > 0;
  double get baseAmount => amount;

  // Budget status
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isCurrent => !isExpired && isActive;
  
  // For transaction matching - exact category comparison
  String get categoryForTransaction => category;

  Budget copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    BudgetPeriod? period,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? spent,
    bool? isActive,
    DateTime? createdAt,
    bool? enableRollover,
    double? rolloverAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      spent: spent ?? this.spent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      enableRollover: enableRollover ?? this.enableRollover,
      rolloverAmount: rolloverAmount ?? this.rolloverAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'amount': amount,
      'period': period.name,
      'category': category,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'spent': spent,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'enableRollover': enableRollover,
      'rolloverAmount': rolloverAmount,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      category: json['category'] as String? ?? '',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      enableRollover: json['enableRollover'] as bool? ?? false,
      rolloverAmount: (json['rolloverAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        amount,
        period,
        category,
        startDate,
        endDate,
        spent,
        isActive,
        createdAt,
        enableRollover,
        rolloverAmount,
      ];
}
