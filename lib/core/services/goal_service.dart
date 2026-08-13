import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/goal_model.dart';
import 'user_bootstrap.dart';
import 'local_data_cache_service.dart';
import 'sync_status_service.dart';

class GoalService {
  static const int goalFetchLimit = 100;
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final LocalDataCacheService _cache = LocalDataCacheService();

  // Create a new goal
  Future<void> createGoal(Goal goal) async {
    try {
      final goalRef = _firestore.collection('goals').doc(goal.id);
      await SyncStatusService().track(() => goalRef.set(goal.toJson()));
      await _cache.upsertGoal(goal.userId, goal);
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  // Update a goal
  Future<void> updateGoal(Goal goal) async {
    try {
      final goalRef = _firestore.collection('goals').doc(goal.id);
      await SyncStatusService().track(() => goalRef.update(goal.toJson()));
      await _cache.upsertGoal(goal.userId, goal);
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId, {String? userId}) async {
    try {
      final goalRef = _firestore.collection('goals').doc(goalId);
      await SyncStatusService().track(() => goalRef.delete());
      if (userId != null) {
        await _cache.removeGoal(userId, goalId);
      }
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  // Get all goals for a user
  Future<List<Goal>> getUserGoals(String userId) async {
    try {
      // Ensure user document exists
      await _ensureUserExists(userId);

      final querySnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(goalFetchLimit)
          .get();

      final goals =
          querySnapshot.docs.map((doc) => Goal.fromJson(doc.data())).toList();
      await _cache.saveGoals(userId, goals);
      return goals;
    } catch (e) {
      debugPrint('❌ GOAL SERVICE: Error getting user goals: $e');
      final cached = await _cache.loadGoals(userId);
      debugPrint('ℹ️ GOAL SERVICE: Returning ${cached.length} cached goals');
      return cached;
    }
  }

  // Update goal progress
  Future<void> updateGoalProgress(String goalId, double amount) async {
    try {
      final goalRef = _firestore.collection('goals').doc(goalId);
      final goalDoc = await goalRef.get();

      if (!goalDoc.exists) {
        throw Exception('Goal not found');
      }

      final goal = Goal.fromJson(goalDoc.data()!);
      final newAmount = goal.currentAmount + amount;

      // Check if goal is completed
      final newStatus =
          newAmount >= goal.targetAmount ? GoalStatus.completed : goal.status;

      final completedAt =
          newStatus == GoalStatus.completed ? DateTime.now() : goal.completedAt;

      await SyncStatusService().track(() => goalRef.update({
            'currentAmount': newAmount,
            'status': newStatus.name,
            'completedAt': completedAt?.toIso8601String(),
          }));
      await _cache.upsertGoal(
        goal.userId,
        goal.copyWith(
          currentAmount: newAmount,
          status: newStatus,
          completedAt: completedAt,
        ),
      );
    } catch (e) {
      throw Exception('Failed to update goal progress: $e');
    }
  }

  // Get goal statistics
  Future<Map<String, dynamic>> getGoalStatistics(String userId) async {
    try {
      final goals = await getUserGoals(userId);

      final activeGoals =
          goals.where((g) => g.status == GoalStatus.active).toList();
      final completedGoals =
          goals.where((g) => g.status == GoalStatus.completed).toList();

      final totalActiveAmount =
          activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
      final totalActiveProgress =
          activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
      final totalCompletedAmount =
          completedGoals.fold(0.0, (sum, g) => sum + g.targetAmount);

      final averageProgress = activeGoals.isNotEmpty
          ? (totalActiveProgress / totalActiveAmount * 100).clamp(0.0, 100.0)
          : 0.0;

      final overdueGoals = activeGoals.where((g) => g.isOverdue).length;
      final nearDeadlineGoals = activeGoals
          .where((g) => g.daysRemaining <= 30 && g.daysRemaining > 0)
          .length;

      return {
        'totalGoals': goals.length,
        'activeGoals': activeGoals.length,
        'completedGoals': completedGoals.length,
        'totalActiveAmount': totalActiveAmount,
        'totalActiveProgress': totalActiveProgress,
        'totalCompletedAmount': totalCompletedAmount,
        'averageProgress': averageProgress,
        'overdueGoals': overdueGoals,
        'nearDeadlineGoals': nearDeadlineGoals,
      };
    } catch (e) {
      throw Exception('Failed to get goal statistics: $e');
    }
  }

  // Generate goal recommendations based on user's financial situation
  Future<List<Map<String, dynamic>>> generateGoalRecommendations(
    String userId,
    double monthlyIncome,
    List<Goal> existingGoals,
  ) async {
    final recommendations = <Map<String, dynamic>>[];

    // Emergency fund recommendation (3-6 months of expenses)
    final emergencyFundGoal =
        existingGoals.where((g) => g.type == GoalType.emergency).isEmpty;
    if (emergencyFundGoal) {
      final emergencyAmount = monthlyIncome * 6; // 6 months of income
      recommendations.add({
        'type': GoalType.emergency,
        'name': 'Emergency Fund',
        'description': 'Build a safety net for unexpected expenses',
        'targetAmount': emergencyAmount,
        'targetDate': DateTime.now().add(const Duration(days: 365)),
        'priority': 'High',
        'icon': 'emergency',
        'color': 0xFFE53E3E, // Red
      });
    }

    // Debt repayment recommendation
    final debtGoals =
        existingGoals.where((g) => g.type == GoalType.debt).length;
    if (debtGoals < 2) {
      recommendations.add({
        'type': GoalType.debt,
        'name': 'Debt Repayment',
        'description': 'Pay off high-interest debt to improve financial health',
        'targetAmount': monthlyIncome * 0.3, // 30% of monthly income
        'targetDate': DateTime.now().add(const Duration(days: 180)),
        'priority': 'High',
        'icon': 'credit_card',
        'color': 0xFFF56505, // Orange
      });
    }

    // Investment recommendation
    final investmentGoals =
        existingGoals.where((g) => g.type == GoalType.investment).isEmpty;
    if (investmentGoals) {
      recommendations.add({
        'type': GoalType.investment,
        'name': 'Investment Portfolio',
        'description': 'Start building wealth through investments',
        'targetAmount': monthlyIncome * 0.2, // 20% of monthly income
        'targetDate': DateTime.now().add(const Duration(days: 365)),
        'priority': 'Medium',
        'icon': 'trending_up',
        'color': 0xFF38A169, // Green
      });
    }

    // Vacation fund recommendation
    final vacationGoals =
        existingGoals.where((g) => g.type == GoalType.vacation).isEmpty;
    if (vacationGoals) {
      recommendations.add({
        'type': GoalType.vacation,
        'name': 'Vacation Fund',
        'description': 'Save for your next dream vacation',
        'targetAmount': monthlyIncome * 0.5, // 50% of monthly income
        'targetDate': DateTime.now().add(const Duration(days: 365)),
        'priority': 'Medium',
        'icon': 'beach_access',
        'color': 0xFF3182CE, // Blue
      });
    }

    return recommendations;
  }

  // Generate unique ID
  String generateId() {
    return _uuid.v4();
  }

  Future<void> _ensureUserExists(String userId) =>
      ensureUserExists(_firestore, userId, logTag: 'GOAL SERVICE');
}
