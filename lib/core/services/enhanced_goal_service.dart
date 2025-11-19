import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:uuid/uuid.dart';
import '../models/goal_model.dart';
import '../models/goal_template_model.dart';
import '../models/shared_goal_model.dart';
import '../models/goal_challenge_model.dart';
import '../models/recurring_goal_model.dart';
import '../models/goal_dependency_model.dart';
import 'goal_template_service.dart';

class EnhancedGoalService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final GoalTemplateService _templateService = GoalTemplateService();
  final Uuid _uuid = const Uuid();

  // ==================== GOAL TEMPLATES ====================

  // Get all goal templates
  Future<List<GoalTemplate>> getGoalTemplates() async {
    return await _templateService.getAllTemplates();
  }

  // Get templates by category
  Future<List<GoalTemplate>> getTemplatesByCategory(GoalTemplateCategory category) async {
    return await _templateService.getTemplatesByCategory(category);
  }

  // Get popular templates
  Future<List<GoalTemplate>> getPopularTemplates() async {
    return await _templateService.getPopularTemplates();
  }

  // Search templates
  Future<List<GoalTemplate>> searchTemplates(String query) async {
    return await _templateService.searchTemplates(query);
  }

  // Create goal from template
  Future<Goal> createGoalFromTemplate(
    GoalTemplate template,
    String userId, {
    double? customAmount,
    int? customDurationMonths,
    String? customName,
  }) async {
    try {
      final goalData = await _templateService.createGoalFromTemplate(
        template,
        userId,
        customAmount: customAmount,
        customDurationMonths: customDurationMonths,
        customName: customName,
      );

      final goal = Goal(
        id: _uuid.v4(),
        userId: userId,
        name: goalData['name'] as String,
        description: goalData['description'] as String,
        type: _mapCategoryToGoalType(goalData['category'] as String),
        targetAmount: goalData['targetAmount'] as double,
        currentAmount: 0.0,
        targetDate: goalData['targetDate'] as DateTime,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        icon: goalData['icon'] as String,
        color: 0xFF0079DC, // Default primary color
        isRecurring: false,
      );

      await _firestore
          .collection('goals')
          .doc(goal.id)
          .set(goal.toJson());

      // Track template usage
      await _templateService.trackTemplateUsage(template.id, userId);

      return goal;
    } catch (e) {
      throw Exception('Failed to create goal from template: $e');
    }
  }

  // ==================== SHARED GOALS ====================

  // Create shared goal
  Future<SharedGoal> createSharedGoal({
    required String name,
    required String description,
    required double targetAmount,
    required DateTime targetDate,
    required String category,
    required String icon,
    required List<String> tags,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    bool isPublic = false,
  }) async {
    try {
      final inviteCode = _generateInviteCode();
      
      final sharedGoal = SharedGoal(
        id: _uuid.v4(),
        name: name,
        description: description,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        targetDate: targetDate,
        category: category,
        icon: icon,
        tags: tags,
        ownerId: ownerId,
        ownerName: ownerName,
        members: [
          SharedGoalMember(
            userId: ownerId,
            userName: ownerName,
            userEmail: ownerEmail,
            role: SharedGoalRole.owner,
            contributionAmount: 0.0,
            contributionPercentage: 0.0,
            joinedAt: DateTime.now(),
          ),
        ],
        status: SharedGoalStatus.active,
        metadata: {},
        isPublic: isPublic,
        inviteCode: inviteCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('shared_goals')
          .doc(sharedGoal.id)
          .set(sharedGoal.toJson());

      return sharedGoal;
    } catch (e) {
      throw Exception('Failed to create shared goal: $e');
    }
  }

  // Join shared goal
  Future<void> joinSharedGoal(String goalId, String userId, String userName, String userEmail) async {
    try {
      final goalDoc = await _firestore
          .collection('shared_goals')
          .doc(goalId)
          .get();

      if (!goalDoc.exists) {
        throw Exception('Shared goal not found');
      }

      final goal = SharedGoal.fromJson(goalDoc.data()!);
      
      if (goal.isFull) {
        throw Exception('Shared goal is full');
      }

      if (goal.isMember(userId)) {
        throw Exception('Already a member of this goal');
      }

      final newMember = SharedGoalMember(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        role: SharedGoalRole.contributor,
        contributionAmount: 0.0,
        contributionPercentage: 0.0,
        joinedAt: DateTime.now(),
      );

      final updatedMembers = [...goal.members, newMember];

      await _firestore
          .collection('shared_goals')
          .doc(goalId)
          .update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to join shared goal: $e');
    }
  }

  // Contribute to shared goal
  Future<void> contributeToSharedGoal(String goalId, String userId, double amount) async {
    try {
      final goalDoc = await _firestore
          .collection('shared_goals')
          .doc(goalId)
          .get();

      if (!goalDoc.exists) {
        throw Exception('Shared goal not found');
      }

      final goal = SharedGoal.fromJson(goalDoc.data()!);
      
      if (!goal.canContribute(userId)) {
        throw Exception('User cannot contribute to this goal');
      }

      final updatedMembers = goal.members.map((member) {
        if (member.userId == userId) {
          return member.copyWith(
            contributionAmount: member.contributionAmount + amount,
            lastContributionAt: DateTime.now(),
          );
        }
        return member;
      }).toList();

      final newCurrentAmount = goal.currentAmount + amount;

      await _firestore
          .collection('shared_goals')
          .doc(goalId)
          .update({
        'currentAmount': newCurrentAmount,
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
        'completedAt': newCurrentAmount >= goal.targetAmount 
            ? DateTime.now().toIso8601String()
            : null,
      });
    } catch (e) {
      throw Exception('Failed to contribute to shared goal: $e');
    }
  }

  // Get user's shared goals
  Future<List<SharedGoal>> getUserSharedGoals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('shared_goals')
          .where('members', arrayContains: {'userId': userId})
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SharedGoal.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ ENHANCED GOAL SERVICE: Error getting shared goals: $e');
      return [];
    }
  }

  // ==================== GOAL CHALLENGES ====================

  // Create goal challenge
  Future<GoalChallenge> createGoalChallenge({
    required String name,
    required String description,
    required ChallengeType type,
    required ChallengeDifficulty difficulty,
    required double targetValue,
    required DateTime startDate,
    required DateTime endDate,
    required String category,
    required String icon,
    required List<String> tags,
    required String creatorId,
    required String creatorName,
    required List<ChallengeReward> rewards,
    bool isPublic = true,
    int maxParticipants = 100,
  }) async {
    try {
      final challenge = GoalChallenge(
        id: _uuid.v4(),
        name: name,
        description: description,
        type: type,
        difficulty: difficulty,
        status: ChallengeStatus.active,
        targetValue: targetValue,
        currentValue: 0.0,
        startDate: startDate,
        endDate: endDate,
        category: category,
        icon: icon,
        tags: tags,
        rewards: rewards,
        participants: [],
        creatorId: creatorId,
        creatorName: creatorName,
        isPublic: isPublic,
        maxParticipants: maxParticipants,
        metadata: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('goal_challenges')
          .doc(challenge.id)
          .set(challenge.toJson());

      return challenge;
    } catch (e) {
      throw Exception('Failed to create goal challenge: $e');
    }
  }

  // Join challenge
  Future<void> joinChallenge(String challengeId, String userId, String userName, String userEmail) async {
    try {
      final challengeDoc = await _firestore
          .collection('goal_challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challenge = GoalChallenge.fromJson(challengeDoc.data()!);
      
      if (!challenge.canJoin(userId)) {
        throw Exception('Cannot join this challenge');
      }

      final newParticipant = ChallengeParticipant(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        progress: 0.0,
        score: 0.0,
        joinedAt: DateTime.now(),
        rewards: [],
        metadata: {},
      );

      final updatedParticipants = [...challenge.participants, newParticipant];

      await _firestore
          .collection('goal_challenges')
          .doc(challengeId)
          .update({
        'participants': updatedParticipants.map((p) => p.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to join challenge: $e');
    }
  }

  // Update challenge progress
  Future<void> updateChallengeProgress(String challengeId, String userId, double progress, double score) async {
    try {
      final challengeDoc = await _firestore
          .collection('goal_challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challenge = GoalChallenge.fromJson(challengeDoc.data()!);
      
      if (!challenge.isParticipant(userId)) {
        throw Exception('User is not a participant in this challenge');
      }

      final updatedParticipants = challenge.participants.map((participant) {
        if (participant.userId == userId) {
          return participant.copyWith(
            progress: progress,
            score: score,
            completedAt: progress >= challenge.targetValue ? DateTime.now() : null,
          );
        }
        return participant;
      }).toList();

      await _firestore
          .collection('goal_challenges')
          .doc(challengeId)
          .update({
        'participants': updatedParticipants.map((p) => p.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update challenge progress: $e');
    }
  }

  // Get available challenges
  Future<List<GoalChallenge>> getAvailableChallenges(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('goal_challenges')
          .where('isPublic', isEqualTo: true)
          .where('status', isEqualTo: ChallengeStatus.active.name)
          .orderBy('createdAt', descending: true)
          .get();

      final challenges = querySnapshot.docs
          .map((doc) => GoalChallenge.fromJson(doc.data()))
          .toList();

      // Filter out challenges user is already participating in
      return challenges.where((challenge) => !challenge.isParticipant(userId)).toList();
    } catch (e) {
      print('❌ ENHANCED GOAL SERVICE: Error getting available challenges: $e');
      return [];
    }
  }

  // ==================== RECURRING GOALS ====================

  // Create recurring goal
  Future<RecurringGoal> createRecurringGoal({
    required String userId,
    required String name,
    required String description,
    required double targetAmount,
    required String category,
    required String icon,
    required List<String> tags,
    required RecurringGoalSettings settings,
  }) async {
    try {
      final recurringGoal = RecurringGoal(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        description: description,
        targetAmount: targetAmount,
        category: category,
        icon: icon,
        tags: tags,
        settings: settings,
        status: RecurringGoalStatus.active,
        instances: [],
        metadata: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create first instance
      final firstInstance = await _createRecurringGoalInstance(recurringGoal, 1);
      final updatedGoal = recurringGoal.copyWith(
        instances: [firstInstance],
        nextRenewalAt: settings.getNextOccurrence(firstInstance.targetDate),
      );

      await _firestore
          .collection('recurring_goals')
          .doc(recurringGoal.id)
          .set(updatedGoal.toJson());

      return updatedGoal;
    } catch (e) {
      throw Exception('Failed to create recurring goal: $e');
    }
  }

  // Create recurring goal instance
  Future<RecurringGoalInstance> _createRecurringGoalInstance(
    RecurringGoal recurringGoal,
    int instanceNumber,
  ) async {
    final startDate = DateTime.now();
    final targetDate = recurringGoal.settings.getNextOccurrence(startDate);

    return RecurringGoalInstance(
      id: _uuid.v4(),
      recurringGoalId: recurringGoal.id,
      name: recurringGoal.name,
      description: recurringGoal.description,
      targetAmount: recurringGoal.targetAmount,
      currentAmount: 0.0,
      startDate: startDate,
      targetDate: targetDate,
      category: recurringGoal.category,
      icon: recurringGoal.icon,
      tags: recurringGoal.tags,
      status: RecurringGoalStatus.active,
      instanceNumber: instanceNumber,
      metadata: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Renew recurring goal
  Future<void> renewRecurringGoal(String recurringGoalId) async {
    try {
      final goalDoc = await _firestore
          .collection('recurring_goals')
          .doc(recurringGoalId)
          .get();

      if (!goalDoc.exists) {
        throw Exception('Recurring goal not found');
      }

      final recurringGoal = RecurringGoal.fromJson(goalDoc.data()!);
      
      if (!recurringGoal.canRenew) {
        throw Exception('Recurring goal cannot be renewed');
      }

      final newInstanceNumber = recurringGoal.instances.length + 1;
      final newInstance = await _createRecurringGoalInstance(recurringGoal, newInstanceNumber);

      final updatedInstances = [...recurringGoal.instances, newInstance];
      final updatedGoal = recurringGoal.copyWith(
        instances: updatedInstances,
        renewalCount: recurringGoal.renewalCount + 1,
        lastRenewedAt: DateTime.now(),
        nextRenewalAt: recurringGoal.settings.getNextOccurrence(newInstance.targetDate),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('recurring_goals')
          .doc(recurringGoalId)
          .update(updatedGoal.toJson());
    } catch (e) {
      throw Exception('Failed to renew recurring goal: $e');
    }
  }

  // ==================== GOAL DEPENDENCIES ====================

  // Create goal dependency
  Future<GoalDependency> createGoalDependency({
    required String sourceGoalId,
    required String targetGoalId,
    required DependencyType type,
    double? thresholdValue,
    String? thresholdType,
    required String description,
  }) async {
    try {
      final dependency = GoalDependency(
        id: _uuid.v4(),
        sourceGoalId: sourceGoalId,
        targetGoalId: targetGoalId,
        type: type,
        status: DependencyStatus.active,
        thresholdValue: thresholdValue,
        thresholdType: thresholdType,
        description: description,
        metadata: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('goal_dependencies')
          .doc(dependency.id)
          .set(dependency.toJson());

      return dependency;
    } catch (e) {
      throw Exception('Failed to create goal dependency: $e');
    }
  }

  // Get goal dependencies
  Future<List<GoalDependency>> getGoalDependencies(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('goal_dependencies')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => GoalDependency.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ ENHANCED GOAL SERVICE: Error getting goal dependencies: $e');
      return [];
    }
  }

  // Get dependency graph
  Future<GoalDependencyGraph> getDependencyGraph(String userId) async {
    try {
      final dependencies = await getGoalDependencies(userId);
      return GoalDependencyGraph.fromDependencies(userId, dependencies);
    } catch (e) {
      throw Exception('Failed to get dependency graph: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  // Generate invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random % chars.length)),
    );
  }

  // Map category string to GoalType enum
  GoalType _mapCategoryToGoalType(String category) {
    switch (category.toLowerCase()) {
      case 'house':
      case 'home':
        return GoalType.home;
      case 'car':
      case 'vehicle':
        return GoalType.other; // Car is not in the enum, use other
      case 'vacation':
      case 'travel':
        return GoalType.vacation;
      case 'education':
      case 'school':
        return GoalType.education;
      case 'emergency':
        return GoalType.emergency;
      case 'retirement':
        return GoalType.investment;
      case 'wedding':
      case 'business':
      case 'health':
      default:
        return GoalType.other;
    }
  }

  // Initialize default templates
  Future<void> initializeDefaultTemplates() async {
    await _templateService.initializeDefaultTemplates();
  }
}
