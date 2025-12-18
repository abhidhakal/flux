import 'package:equatable/equatable.dart';

enum GoalType {
  savings,
  debt,
  investment,
  emergency,
  vacation,
  home,
  education,
  other,
}

enum GoalStatus {
  active,
  completed,
  paused,
  cancelled,
}

class Goal extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String description;
  final GoalType type;
  final double targetAmount;
  final double currentAmount;
  final GoalStatus status;
  final DateTime targetDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? icon;
  final int color;
  final bool isRecurring;
  final String? recurringPeriod; // monthly, yearly, etc.

  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.type,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    required this.targetDate,
    required this.createdAt,
    this.completedAt,
    this.icon,
    required this.color,
    this.isRecurring = false,
    this.recurringPeriod,
  });

  // Getters
  double get progress => targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
  double get remaining => targetAmount - currentAmount;
  bool get isCompleted => status == GoalStatus.completed;
  bool get isOverdue => targetDate.isBefore(DateTime.now()) && !isCompleted;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
  double get dailyRequired => remaining / daysRemaining.clamp(1, 365);

  // Progress percentage for UI
  double get progressPercentage => (progress * 100).clamp(0.0, 100.0);

  // Goal completion status
  String get statusText {
    switch (status) {
      case GoalStatus.active:
        return isOverdue ? 'Overdue' : 'Active';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.paused:
        return 'Paused';
      case GoalStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Goal type display name
  String get typeDisplayName {
    switch (type) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.debt:
        return 'Debt Repayment';
      case GoalType.investment:
        return 'Investment';
      case GoalType.emergency:
        return 'Emergency Fund';
      case GoalType.vacation:
        return 'Vacation';
      case GoalType.home:
        return 'Home Purchase';
      case GoalType.education:
        return 'Education';
      case GoalType.other:
        return 'Other';
    }
  }

  // Copy with method
  Goal copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    GoalType? type,
    double? targetAmount,
    double? currentAmount,
    GoalStatus? status,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? completedAt,
    String? icon,
    int? color,
    bool? isRecurring,
    String? recurringPeriod,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPeriod: recurringPeriod ?? this.recurringPeriod,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'type': type.name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'status': status.name,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'icon': icon,
      'color': color,
      'isRecurring': isRecurring,
      'recurringPeriod': recurringPeriod,
    };
  }

  // From JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: GoalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GoalType.other,
      ),
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.active,
      ),
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      icon: json['icon'] as String?,
      color: json['color'] as int,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringPeriod: json['recurringPeriod'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        type,
        targetAmount,
        currentAmount,
        status,
        targetDate,
        createdAt,
        completedAt,
        icon,
        color,
        isRecurring,
        recurringPeriod,
      ];
}

extension GoalTypeX on GoalType {
  String get typeDisplayName {
    switch (this) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.debt:
        return 'Debt Repayment';
      case GoalType.investment:
        return 'Investment';
      case GoalType.emergency:
        return 'Emergency Fund';
      case GoalType.vacation:
        return 'Vacation';
      case GoalType.home:
        return 'Home Purchase';
      case GoalType.education:
        return 'Education';
      case GoalType.other:
        return 'Other';
    }
  }
}
