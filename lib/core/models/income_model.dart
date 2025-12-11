import 'package:equatable/equatable.dart';

class Income extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String? notes;
  final String category; // e.g., 'Salary', 'Freelance', etc.
  final DateTime createdAt;

  const Income({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    this.notes,
    this.category = 'Salary',
    required this.createdAt,
  });

  Income copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    String? notes,
    String? category,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null 
          ? DateTime.parse(json['date'] as String) 
          : DateTime.now(),
      notes: json['notes'] as String?,
      category: json['category'] as String? ?? 'Salary',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, amount, date, notes, category, createdAt];
}
