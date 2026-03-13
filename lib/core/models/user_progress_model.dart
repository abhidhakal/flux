import 'package:equatable/equatable.dart';

enum ProgressMetricType {
  currentStreak,
  longestStreak,
  activeDays,
  totalTransactions,
}

class AchievementBadgeDefinition extends Equatable {
  final String id;
  final String title;
  final String description;
  final ProgressMetricType metricType;
  final int threshold;
  final String iconKey;

  const AchievementBadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.metricType,
    required this.threshold,
    required this.iconKey,
  });

  bool isUnlocked(UserProgressSnapshot snapshot) {
    switch (metricType) {
      case ProgressMetricType.currentStreak:
        return snapshot.currentStreak >= threshold;
      case ProgressMetricType.longestStreak:
        return snapshot.longestStreak >= threshold;
      case ProgressMetricType.activeDays:
        return snapshot.activeDays >= threshold;
      case ProgressMetricType.totalTransactions:
        return snapshot.totalTransactions >= threshold;
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        metricType,
        threshold,
        iconKey,
      ];
}

class UserProgressSnapshot extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final int activeDays;
  final int totalTransactions;
  final DateTime? lastLoggedDate;
  final bool isStreakActive;
  final List<String> earnedBadgeIds;
  final DateTime updatedAt;

  const UserProgressSnapshot({
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDays,
    required this.totalTransactions,
    required this.lastLoggedDate,
    required this.isStreakActive,
    required this.earnedBadgeIds,
    required this.updatedAt,
  });

  UserProgressSnapshot.empty()
      : currentStreak = 0,
        longestStreak = 0,
        activeDays = 0,
        totalTransactions = 0,
        lastLoggedDate = null,
        isStreakActive = false,
        earnedBadgeIds = const [],
        updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'activeDays': activeDays,
      'totalTransactions': totalTransactions,
      'lastLoggedDate': lastLoggedDate?.toIso8601String(),
      'isStreakActive': isStreakActive,
      'earnedBadgeIds': earnedBadgeIds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProgressSnapshot.fromJson(Map<String, dynamic> json) {
    return UserProgressSnapshot(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      activeDays: json['activeDays'] as int? ?? 0,
      totalTransactions: json['totalTransactions'] as int? ?? 0,
      lastLoggedDate: json['lastLoggedDate'] != null
          ? DateTime.parse(json['lastLoggedDate'] as String)
          : null,
      isStreakActive: json['isStreakActive'] as bool? ?? false,
      earnedBadgeIds: List<String>.from(json['earnedBadgeIds'] ?? const []),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  UserProgressSnapshot copyWith({
    int? currentStreak,
    int? longestStreak,
    int? activeDays,
    int? totalTransactions,
    Object? lastLoggedDate = _unset,
    bool? isStreakActive,
    List<String>? earnedBadgeIds,
    DateTime? updatedAt,
  }) {
    return UserProgressSnapshot(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      activeDays: activeDays ?? this.activeDays,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      lastLoggedDate: identical(lastLoggedDate, _unset)
          ? this.lastLoggedDate
          : lastLoggedDate as DateTime?,
      isStreakActive: isStreakActive ?? this.isStreakActive,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        currentStreak,
        longestStreak,
        activeDays,
        totalTransactions,
        lastLoggedDate,
        isStreakActive,
        earnedBadgeIds,
        updatedAt,
      ];
}

const Object _unset = Object();
