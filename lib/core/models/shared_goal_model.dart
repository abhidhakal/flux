import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum SharedGoalRole {
  owner,
  contributor,
  viewer,
}

enum SharedGoalStatus {
  active,
  paused,
  completed,
  cancelled,
}

class SharedGoalMember {
  final String userId;
  final String userName;
  final String userEmail;
  final SharedGoalRole role;
  final double contributionAmount;
  final double contributionPercentage;
  final DateTime joinedAt;
  final DateTime? lastContributionAt;
  final bool isActive;

  const SharedGoalMember({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.contributionAmount,
    required this.contributionPercentage,
    required this.joinedAt,
    this.lastContributionAt,
    this.isActive = true,
  });

  factory SharedGoalMember.fromJson(Map<String, dynamic> json) {
    return SharedGoalMember(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      role: SharedGoalRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => SharedGoalRole.viewer,
      ),
      contributionAmount: (json['contributionAmount'] as num).toDouble(),
      contributionPercentage: (json['contributionPercentage'] as num).toDouble(),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      lastContributionAt: json['lastContributionAt'] != null 
          ? DateTime.parse(json['lastContributionAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'role': role.name,
      'contributionAmount': contributionAmount,
      'contributionPercentage': contributionPercentage,
      'joinedAt': joinedAt.toIso8601String(),
      'lastContributionAt': lastContributionAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  SharedGoalMember copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    SharedGoalRole? role,
    double? contributionAmount,
    double? contributionPercentage,
    DateTime? joinedAt,
    DateTime? lastContributionAt,
    bool? isActive,
  }) {
    return SharedGoalMember(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      contributionPercentage: contributionPercentage ?? this.contributionPercentage,
      joinedAt: joinedAt ?? this.joinedAt,
      lastContributionAt: lastContributionAt ?? this.lastContributionAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SharedGoal {
  final String id;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String category;
  final String icon;
  final List<String> tags;
  final String ownerId;
  final String ownerName;
  final List<SharedGoalMember> members;
  final SharedGoalStatus status;
  final Map<String, dynamic> metadata;
  final bool isPublic;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const SharedGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.category,
    required this.icon,
    required this.tags,
    required this.ownerId,
    required this.ownerName,
    required this.members,
    required this.status,
    required this.metadata,
    this.isPublic = false,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory SharedGoal.fromJson(Map<String, dynamic> json) {
    return SharedGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      category: json['category'] as String,
      icon: json['icon'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      members: (json['members'] as List<dynamic>?)
          ?.map((member) => SharedGoalMember.fromJson(member as Map<String, dynamic>))
          .toList() ?? [],
      status: SharedGoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SharedGoalStatus.active,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isPublic: json['isPublic'] as bool? ?? false,
      inviteCode: json['inviteCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'icon': icon,
      'tags': tags,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'members': members.map((member) => member.toJson()).toList(),
      'status': status.name,
      'metadata': metadata,
      'isPublic': isPublic,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Computed properties
  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;
  double get remainingAmount => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;
  int get memberCount => members.length;
  int get activeMemberCount => members.where((m) => m.isActive).length;
  double get averageContribution => memberCount > 0 ? currentAmount / memberCount : 0;
  bool get isFull => memberCount >= 10; // Default max of 10 members

  // Get member by user ID
  SharedGoalMember? getMember(String userId) {
    try {
      return members.firstWhere((member) => member.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is member
  bool isMember(String userId) => getMember(userId) != null;

  // Check if user is owner
  bool isOwner(String userId) => ownerId == userId;

  // Check if user can contribute
  bool canContribute(String userId) {
    final member = getMember(userId);
    return member != null && 
           member.isActive && 
           (member.role == SharedGoalRole.owner || member.role == SharedGoalRole.contributor);
  }

  // Check if user can edit
  bool canEdit(String userId) {
    final member = getMember(userId);
    return member != null && 
           member.isActive && 
           (member.role == SharedGoalRole.owner || member.role == SharedGoalRole.contributor);
  }

  SharedGoal copyWith({
    String? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? icon,
    List<String>? tags,
    String? ownerId,
    String? ownerName,
    List<SharedGoalMember>? members,
    SharedGoalStatus? status,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return SharedGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      members: members ?? this.members,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      isPublic: isPublic ?? this.isPublic,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'SharedGoal(id: $id, name: $name, members: $memberCount, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
