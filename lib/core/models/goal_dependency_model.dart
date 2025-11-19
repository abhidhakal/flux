import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum DependencyType {
  prerequisite, // Goal A must be completed before Goal B can start
  parallel, // Goals can be worked on simultaneously
  sequential, // Goals must be completed in order
  alternative, // Only one of the goals needs to be completed
  milestone, // Goal A reaching a milestone unlocks Goal B
  resource, // Goals share resources (budget, time, etc.)
}

enum DependencyStatus {
  active,
  satisfied,
  blocked,
  cancelled,
}

class GoalDependency {
  final String id;
  final String sourceGoalId; // The goal that affects another
  final String targetGoalId; // The goal that is affected
  final DependencyType type;
  final DependencyStatus status;
  final double? thresholdValue; // For milestone dependencies
  final String? thresholdType; // 'percentage', 'amount', 'date'
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalDependency({
    required this.id,
    required this.sourceGoalId,
    required this.targetGoalId,
    required this.type,
    required this.status,
    this.thresholdValue,
    this.thresholdType,
    required this.description,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalDependency.fromJson(Map<String, dynamic> json) {
    return GoalDependency(
      id: json['id'] as String,
      sourceGoalId: json['sourceGoalId'] as String,
      targetGoalId: json['targetGoalId'] as String,
      type: DependencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DependencyType.prerequisite,
      ),
      status: DependencyStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DependencyStatus.active,
      ),
      thresholdValue: json['thresholdValue'] != null 
          ? (json['thresholdValue'] as num).toDouble()
          : null,
      thresholdType: json['thresholdType'] as String?,
      description: json['description'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceGoalId': sourceGoalId,
      'targetGoalId': targetGoalId,
      'type': type.name,
      'status': status.name,
      'thresholdValue': thresholdValue,
      'thresholdType': thresholdType,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Check if dependency is satisfied
  bool isSatisfied({
    required double sourceProgress,
    required double sourceAmount,
    required bool sourceCompleted,
    required DateTime sourceCompletedAt,
  }) {
    switch (type) {
      case DependencyType.prerequisite:
        return sourceCompleted;
      case DependencyType.milestone:
        if (thresholdType == 'percentage') {
          return sourceProgress >= (thresholdValue ?? 0);
        } else if (thresholdType == 'amount') {
          return sourceAmount >= (thresholdValue ?? 0);
        }
        return false;
      case DependencyType.sequential:
        return sourceCompleted;
      case DependencyType.parallel:
        return true; // Parallel goals can always be active
      case DependencyType.alternative:
        return sourceCompleted; // At least one alternative is completed
      case DependencyType.resource:
        return true; // Resource dependencies are always active
    }
  }

  // Get dependency description based on type
  String getDependencyDescription() {
    switch (type) {
      case DependencyType.prerequisite:
        return 'Must complete source goal first';
      case DependencyType.milestone:
        return 'Reach ${thresholdValue?.toStringAsFixed(0)}${thresholdType == 'percentage' ? '%' : ''} of source goal';
      case DependencyType.sequential:
        return 'Complete in order after source goal';
      case DependencyType.parallel:
        return 'Can work on simultaneously';
      case DependencyType.alternative:
        return 'Alternative to source goal';
      case DependencyType.resource:
        return 'Shares resources with source goal';
    }
  }

  GoalDependency copyWith({
    String? id,
    String? sourceGoalId,
    String? targetGoalId,
    DependencyType? type,
    DependencyStatus? status,
    double? thresholdValue,
    String? thresholdType,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalDependency(
      id: id ?? this.id,
      sourceGoalId: sourceGoalId ?? this.sourceGoalId,
      targetGoalId: targetGoalId ?? this.targetGoalId,
      type: type ?? this.type,
      status: status ?? this.status,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      thresholdType: thresholdType ?? this.thresholdType,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'GoalDependency(id: $id, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalDependency && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class GoalDependencyGraph {
  final String userId;
  final List<GoalDependency> dependencies;
  final Map<String, List<String>> adjacencyList; // goalId -> list of dependent goal IDs
  final Map<String, List<String>> reverseAdjacencyList; // goalId -> list of prerequisite goal IDs

  const GoalDependencyGraph({
    required this.userId,
    required this.dependencies,
    required this.adjacencyList,
    required this.reverseAdjacencyList,
  });

  factory GoalDependencyGraph.fromDependencies(String userId, List<GoalDependency> dependencies) {
    final adjacencyList = <String, List<String>>{};
    final reverseAdjacencyList = <String, List<String>>{};

    for (final dependency in dependencies) {
      // Add to adjacency list (source -> target)
      adjacencyList.putIfAbsent(dependency.sourceGoalId, () => []);
      adjacencyList[dependency.sourceGoalId]!.add(dependency.targetGoalId);

      // Add to reverse adjacency list (target -> source)
      reverseAdjacencyList.putIfAbsent(dependency.targetGoalId, () => []);
      reverseAdjacencyList[dependency.targetGoalId]!.add(dependency.sourceGoalId);
    }

    return GoalDependencyGraph(
      userId: userId,
      dependencies: dependencies,
      adjacencyList: adjacencyList,
      reverseAdjacencyList: reverseAdjacencyList,
    );
  }

  // Get goals that depend on the given goal
  List<String> getDependentGoals(String goalId) {
    return adjacencyList[goalId] ?? [];
  }

  // Get prerequisites for the given goal
  List<String> getPrerequisites(String goalId) {
    return reverseAdjacencyList[goalId] ?? [];
  }

  // Check if goal can be started (all prerequisites satisfied)
  bool canStartGoal(String goalId, Map<String, Map<String, dynamic>> goalStatuses) {
    final prerequisites = getPrerequisites(goalId);
    
    for (final prereqId in prerequisites) {
      final prereqStatus = goalStatuses[prereqId];
      if (prereqStatus == null) return false;
      
      final dependency = dependencies.firstWhere(
        (d) => d.sourceGoalId == prereqId && d.targetGoalId == goalId,
        orElse: () => throw Exception('Dependency not found'),
      );
      
      if (!dependency.isSatisfied(
        sourceProgress: prereqStatus['progress'] ?? 0.0,
        sourceAmount: prereqStatus['amount'] ?? 0.0,
        sourceCompleted: prereqStatus['completed'] ?? false,
        sourceCompletedAt: prereqStatus['completedAt'] ?? DateTime.now(),
      )) {
        return false;
      }
    }
    
    return true;
  }

  // Get blocked goals (goals that cannot be started due to unmet dependencies)
  List<String> getBlockedGoals(Map<String, Map<String, dynamic>> goalStatuses) {
    final blockedGoals = <String>[];
    
    for (final goalId in reverseAdjacencyList.keys) {
      if (!canStartGoal(goalId, goalStatuses)) {
        blockedGoals.add(goalId);
      }
    }
    
    return blockedGoals;
  }

  // Get available goals (goals that can be started)
  List<String> getAvailableGoals(Map<String, Map<String, dynamic>> goalStatuses) {
    final availableGoals = <String>[];
    
    for (final goalId in reverseAdjacencyList.keys) {
      if (canStartGoal(goalId, goalStatuses)) {
        availableGoals.add(goalId);
      }
    }
    
    return availableGoals;
  }

  // Get goal execution order (topological sort)
  List<String> getExecutionOrder(Map<String, Map<String, dynamic>> goalStatuses) {
    final visited = <String>{};
    final tempMarked = <String>{};
    final result = <String>[];

    void visit(String goalId) {
      if (tempMarked.contains(goalId)) {
        throw Exception('Circular dependency detected');
      }
      if (visited.contains(goalId)) return;

      tempMarked.add(goalId);
      
      final dependents = getDependentGoals(goalId);
      for (final dependent in dependents) {
        visit(dependent);
      }
      
      tempMarked.remove(goalId);
      visited.add(goalId);
      result.add(goalId);
    }

    for (final goalId in reverseAdjacencyList.keys) {
      if (!visited.contains(goalId)) {
        visit(goalId);
      }
    }

    return result.reversed.toList();
  }

  // Check for circular dependencies
  bool hasCircularDependency() {
    try {
      getExecutionOrder({});
      return false;
    } catch (e) {
      return true;
    }
  }

  // Get dependency chain for a goal
  List<String> getDependencyChain(String goalId) {
    final chain = <String>[];
    final visited = <String>{};

    void buildChain(String currentGoalId) {
      if (visited.contains(currentGoalId)) return;
      
      visited.add(currentGoalId);
      chain.add(currentGoalId);
      
      final prerequisites = getPrerequisites(currentGoalId);
      for (final prereq in prerequisites) {
        buildChain(prereq);
      }
    }

    buildChain(goalId);
    return chain;
  }

  // Get impact analysis (what happens if a goal is completed/changed)
  Map<String, dynamic> getImpactAnalysis(String goalId, Map<String, Map<String, dynamic>> goalStatuses) {
    final dependents = getDependentGoals(goalId);
    final newlyAvailable = <String>[];
    final affectedGoals = <String>[];

    for (final dependentId in dependents) {
      affectedGoals.add(dependentId);
      if (canStartGoal(dependentId, goalStatuses)) {
        newlyAvailable.add(dependentId);
      }
    }

    return {
      'directDependents': dependents,
      'newlyAvailableGoals': newlyAvailable,
      'affectedGoals': affectedGoals,
      'totalImpact': dependents.length,
    };
  }
}
