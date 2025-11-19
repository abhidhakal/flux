import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum ChallengeType {
  savingsStreak,
  goalCompletion,
  contributionAmount,
  teamCollaboration,
  milestoneAchievement,
  categoryMastery,
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  expert,
}

enum ChallengeStatus {
  active,
  completed,
  expired,
  cancelled,
}

enum ChallengeRewardType {
  badge,
  points,
  achievement,
  bonus,
  recognition,
}

class ChallengeReward {
  final String id;
  final String name;
  final String description;
  final ChallengeRewardType type;
  final String icon;
  final int points;
  final Map<String, dynamic> metadata;

  const ChallengeReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.points,
    required this.metadata,
  });

  factory ChallengeReward.fromJson(Map<String, dynamic> json) {
    return ChallengeReward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ChallengeRewardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeRewardType.points,
      ),
      icon: json['icon'] as String,
      points: json['points'] as int,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'icon': icon,
      'points': points,
      'metadata': metadata,
    };
  }
}

class ChallengeParticipant {
  final String userId;
  final String userName;
  final String userEmail;
  final double progress;
  final double score;
  final DateTime joinedAt;
  final DateTime? completedAt;
  final List<ChallengeReward> rewards;
  final Map<String, dynamic> metadata;

  const ChallengeParticipant({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.progress,
    required this.score,
    required this.joinedAt,
    this.completedAt,
    required this.rewards,
    required this.metadata,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      progress: (json['progress'] as num).toDouble(),
      score: (json['score'] as num).toDouble(),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      rewards: (json['rewards'] as List<dynamic>?)
          ?.map((reward) => ChallengeReward.fromJson(reward as Map<String, dynamic>))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'progress': progress,
      'score': score,
      'joinedAt': joinedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rewards': rewards.map((reward) => reward.toJson()).toList(),
      'metadata': metadata,
    };
  }

  bool get isCompleted => completedAt != null;
  int get totalPoints => rewards.fold(0, (sum, reward) => sum + reward.points);

  ChallengeParticipant copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    double? progress,
    double? score,
    DateTime? joinedAt,
    DateTime? completedAt,
    List<ChallengeReward>? rewards,
    Map<String, dynamic>? metadata,
  }) {
    return ChallengeParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      progress: progress ?? this.progress,
      score: score ?? this.score,
      joinedAt: joinedAt ?? this.joinedAt,
      completedAt: completedAt ?? this.completedAt,
      rewards: rewards ?? this.rewards,
      metadata: metadata ?? this.metadata,
    );
  }
}

class GoalChallenge {
  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final ChallengeStatus status;
  final double targetValue;
  final double currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final String icon;
  final List<String> tags;
  final List<ChallengeReward> rewards;
  final List<ChallengeParticipant> participants;
  final String creatorId;
  final String creatorName;
  final bool isPublic;
  final int maxParticipants;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.status,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.icon,
    required this.tags,
    required this.rewards,
    required this.participants,
    required this.creatorId,
    required this.creatorName,
    this.isPublic = true,
    this.maxParticipants = 100,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalChallenge.fromJson(Map<String, dynamic> json) {
    return GoalChallenge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.savingsStreak,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => ChallengeDifficulty.medium,
      ),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChallengeStatus.active,
      ),
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      category: json['category'] as String,
      icon: json['icon'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      rewards: (json['rewards'] as List<dynamic>?)
          ?.map((reward) => ChallengeReward.fromJson(reward as Map<String, dynamic>))
          .toList() ?? [],
      participants: (json['participants'] as List<dynamic>?)
          ?.map((participant) => ChallengeParticipant.fromJson(participant as Map<String, dynamic>))
          .toList() ?? [],
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      isPublic: json['isPublic'] as bool? ?? true,
      maxParticipants: json['maxParticipants'] as int? ?? 100,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'status': status.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'category': category,
      'icon': icon,
      'tags': tags,
      'rewards': rewards.map((reward) => reward.toJson()).toList(),
      'participants': participants.map((participant) => participant.toJson()).toList(),
      'creatorId': creatorId,
      'creatorName': creatorName,
      'isPublic': isPublic,
      'maxParticipants': maxParticipants,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  double get progressPercentage => targetValue > 0 ? (currentValue / targetValue) * 100 : 0;
  bool get isActive => status == ChallengeStatus.active && DateTime.now().isBefore(endDate);
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isCompleted => currentValue >= targetValue;
  int get participantCount => participants.length;
  int get completedCount => participants.where((p) => p.isCompleted).length;
  bool get isFull => participantCount >= maxParticipants;
  Duration get timeRemaining => endDate.difference(DateTime.now());
  bool get isStartingSoon => DateTime.now().difference(startDate).inDays <= 7;

  // Get participant by user ID
  ChallengeParticipant? getParticipant(String userId) {
    try {
      return participants.firstWhere((participant) => participant.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is participant
  bool isParticipant(String userId) => getParticipant(userId) != null;

  // Check if user can join
  bool canJoin(String userId) {
    return isActive && 
           !isFull && 
           !isParticipant(userId) && 
           status == ChallengeStatus.active;
  }

  // Get leaderboard (top participants by score)
  List<ChallengeParticipant> get leaderboard {
    final sortedParticipants = List<ChallengeParticipant>.from(participants);
    sortedParticipants.sort((a, b) => b.score.compareTo(a.score));
    return sortedParticipants;
  }

  // Get top performer
  ChallengeParticipant? get topPerformer {
    if (participants.isEmpty) return null;
    return leaderboard.first;
  }

  // Get average score
  double get averageScore {
    if (participants.isEmpty) return 0;
    return participants.fold(0.0, (sum, p) => sum + p.score) / participants.length;
  }

  // Get completion rate
  double get completionRate {
    if (participants.isEmpty) return 0;
    return (completedCount / participants.length) * 100;
  }

  GoalChallenge copyWith({
    String? id,
    String? name,
    String? description,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    ChallengeStatus? status,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? icon,
    List<String>? tags,
    List<ChallengeReward>? rewards,
    List<ChallengeParticipant>? participants,
    String? creatorId,
    String? creatorName,
    bool? isPublic,
    int? maxParticipants,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalChallenge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      rewards: rewards ?? this.rewards,
      participants: participants ?? this.participants,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      isPublic: isPublic ?? this.isPublic,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'GoalChallenge(id: $id, name: $name, type: $type, participants: $participantCount, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalChallenge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
