
enum RecurrenceType {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

enum RecurringGoalStatus {
  active,
  paused,
  completed,
  cancelled,
}

class RecurringGoalSettings {
  final RecurrenceType type;
  final int interval; // e.g., every 2 weeks, every 3 months
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool autoRenew;
  final int maxRenewals; // -1 for unlimited
  final Map<String, dynamic> metadata;

  const RecurringGoalSettings({
    required this.type,
    this.interval = 1,
    this.customStartDate,
    this.customEndDate,
    this.autoRenew = true,
    this.maxRenewals = -1,
    required this.metadata,
  });

  factory RecurringGoalSettings.fromJson(Map<String, dynamic> json) {
    return RecurringGoalSettings(
      type: RecurrenceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecurrenceType.monthly,
      ),
      interval: json['interval'] as int? ?? 1,
      customStartDate: json['customStartDate'] != null 
          ? DateTime.parse(json['customStartDate'] as String)
          : null,
      customEndDate: json['customEndDate'] != null 
          ? DateTime.parse(json['customEndDate'] as String)
          : null,
      autoRenew: json['autoRenew'] as bool? ?? true,
      maxRenewals: json['maxRenewals'] as int? ?? -1,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'interval': interval,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
      'autoRenew': autoRenew,
      'maxRenewals': maxRenewals,
      'metadata': metadata,
    };
  }

  // Calculate next occurrence date
  DateTime getNextOccurrence(DateTime fromDate) {
    switch (type) {
      case RecurrenceType.daily:
        return fromDate.add(Duration(days: interval));
      case RecurrenceType.weekly:
        return fromDate.add(Duration(days: interval * 7));
      case RecurrenceType.monthly:
        return DateTime(fromDate.year, fromDate.month + interval, fromDate.day);
      case RecurrenceType.quarterly:
        return DateTime(fromDate.year, fromDate.month + (interval * 3), fromDate.day);
      case RecurrenceType.yearly:
        return DateTime(fromDate.year + interval, fromDate.month, fromDate.day);
      case RecurrenceType.custom:
        if (customStartDate != null && customEndDate != null) {
          final duration = customEndDate!.difference(customStartDate!);
          return fromDate.add(duration);
        }
        return fromDate.add(Duration(days: interval));
    }
  }

  // Check if should auto-renew
  bool shouldAutoRenew(int currentRenewalCount) {
    if (!autoRenew) return false;
    if (maxRenewals == -1) return true;
    return currentRenewalCount < maxRenewals;
  }
}

class RecurringGoalInstance {
  final String id;
  final String recurringGoalId;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime targetDate;
  final String category;
  final String icon;
  final List<String> tags;
  final RecurringGoalStatus status;
  final int instanceNumber; // 1st, 2nd, 3rd instance, etc.
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringGoalInstance({
    required this.id,
    required this.recurringGoalId,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.targetDate,
    required this.category,
    required this.icon,
    required this.tags,
    required this.status,
    required this.instanceNumber,
    this.completedAt,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringGoalInstance.fromJson(Map<String, dynamic> json) {
    return RecurringGoalInstance(
      id: json['id'] as String,
      recurringGoalId: json['recurringGoalId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      targetDate: DateTime.parse(json['targetDate'] as String),
      category: json['category'] as String,
      icon: json['icon'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      status: RecurringGoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RecurringGoalStatus.active,
      ),
      instanceNumber: json['instanceNumber'] as int,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recurringGoalId': recurringGoalId,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'icon': icon,
      'tags': tags,
      'status': status.name,
      'instanceNumber': instanceNumber,
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;
  double get remainingAmount => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;
  Duration get timeRemaining => targetDate.difference(DateTime.now());
  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;

  RecurringGoalInstance copyWith({
    String? id,
    String? recurringGoalId,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    String? category,
    String? icon,
    List<String>? tags,
    RecurringGoalStatus? status,
    int? instanceNumber,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringGoalInstance(
      id: id ?? this.id,
      recurringGoalId: recurringGoalId ?? this.recurringGoalId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      instanceNumber: instanceNumber ?? this.instanceNumber,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RecurringGoal {
  final String id;
  final String userId;
  final String name;
  final String description;
  final double targetAmount;
  final String category;
  final String icon;
  final List<String> tags;
  final RecurringGoalSettings settings;
  final RecurringGoalStatus status;
  final List<RecurringGoalInstance> instances;
  final int renewalCount;
  final DateTime? lastRenewedAt;
  final DateTime? nextRenewalAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.category,
    required this.icon,
    required this.tags,
    required this.settings,
    required this.status,
    required this.instances,
    this.renewalCount = 0,
    this.lastRenewedAt,
    this.nextRenewalAt,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringGoal.fromJson(Map<String, dynamic> json) {
    return RecurringGoal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      category: json['category'] as String,
      icon: json['icon'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      settings: RecurringGoalSettings.fromJson(json['settings'] as Map<String, dynamic>),
      status: RecurringGoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RecurringGoalStatus.active,
      ),
      instances: (json['instances'] as List<dynamic>?)
          ?.map((instance) => RecurringGoalInstance.fromJson(instance as Map<String, dynamic>))
          .toList() ?? [],
      renewalCount: json['renewalCount'] as int? ?? 0,
      lastRenewedAt: json['lastRenewedAt'] != null 
          ? DateTime.parse(json['lastRenewedAt'] as String)
          : null,
      nextRenewalAt: json['nextRenewalAt'] != null 
          ? DateTime.parse(json['nextRenewalAt'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'category': category,
      'icon': icon,
      'tags': tags,
      'settings': settings.toJson(),
      'status': status.name,
      'instances': instances.map((instance) => instance.toJson()).toList(),
      'renewalCount': renewalCount,
      'lastRenewedAt': lastRenewedAt?.toIso8601String(),
      'nextRenewalAt': nextRenewalAt?.toIso8601String(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  int get totalInstances => instances.length;
  int get completedInstances => instances.where((i) => i.isCompleted).length;
  int get activeInstances => instances.where((i) => i.status == RecurringGoalStatus.active).length;
  double get completionRate => totalInstances > 0 ? (completedInstances / totalInstances) * 100 : 0;
  double get totalAmountSaved => instances.fold(0.0, (sum, i) => sum + i.currentAmount);
  double get averageInstanceAmount => totalInstances > 0 ? totalAmountSaved / totalInstances : 0;
  bool get isActive => status == RecurringGoalStatus.active;
  bool get canRenew => settings.shouldAutoRenew(renewalCount) && isActive;

  // Get current active instance
  RecurringGoalInstance? get currentInstance {
    try {
      return instances
          .where((i) => i.status == RecurringGoalStatus.active)
          .first;
    } catch (e) {
      return null;
    }
  }

  // Get next instance date
  DateTime? getNextInstanceDate() {
    if (instances.isEmpty) return null;
    final lastInstance = instances.last;
    return settings.getNextOccurrence(lastInstance.targetDate);
  }

  // Check if needs renewal
  bool needsRenewal() {
    if (!canRenew) return false;
    if (nextRenewalAt == null) return false;
    return DateTime.now().isAfter(nextRenewalAt!) && currentInstance == null;
  }

  RecurringGoal copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? targetAmount,
    String? category,
    String? icon,
    List<String>? tags,
    RecurringGoalSettings? settings,
    RecurringGoalStatus? status,
    List<RecurringGoalInstance>? instances,
    int? renewalCount,
    DateTime? lastRenewedAt,
    DateTime? nextRenewalAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      instances: instances ?? this.instances,
      renewalCount: renewalCount ?? this.renewalCount,
      lastRenewedAt: lastRenewedAt ?? this.lastRenewedAt,
      nextRenewalAt: nextRenewalAt ?? this.nextRenewalAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RecurringGoal(id: $id, name: $name, instances: $totalInstances, renewals: $renewalCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurringGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
