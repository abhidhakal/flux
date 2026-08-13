import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';

/// Small user-scoped cache used as a rendering fallback when Firestore is
/// unavailable. Firestore remains authoritative; this cache is never used to
/// silently overwrite remote data.
class LocalDataCacheService {
  static final LocalDataCacheService _instance =
      LocalDataCacheService._internal();
  factory LocalDataCacheService() => _instance;
  LocalDataCacheService._internal();

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  String _key(String type, String userId) => 'cache_${type}_$userId';

  Future<void> saveTransactions(
      String userId, List<Transaction> transactions) async {
    final prefs = await _prefs;
    await prefs.setString(
      _key('transactions', userId),
      jsonEncode(
          transactions.map((transaction) => transaction.toJson()).toList()),
    );
  }

  Future<List<Transaction>> loadTransactions(String userId) async {
    final raw = (await _prefs).getString(_key('transactions', userId));
    if (raw == null) return [];
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return values
          .map(
              (value) => Transaction.fromJson(Map<String, dynamic>.from(value)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertTransaction(String userId, Transaction transaction) async {
    final items = await loadTransactions(userId);
    final index = items.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      items.add(transaction);
    } else {
      items[index] = transaction;
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    await saveTransactions(userId, items);
  }

  Future<void> removeTransaction(String userId, String transactionId) async {
    final items = await loadTransactions(userId);
    items.removeWhere((item) => item.id == transactionId);
    await saveTransactions(userId, items);
  }

  Future<void> saveBudgets(String userId, List<Budget> budgets) async {
    final prefs = await _prefs;
    await prefs.setString(
      _key('budgets', userId),
      jsonEncode(budgets.map((budget) => budget.toJson()).toList()),
    );
  }

  Future<List<Budget>> loadBudgets(String userId) async {
    final raw = (await _prefs).getString(_key('budgets', userId));
    if (raw == null) return [];
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return values
          .map((value) => Budget.fromJson(Map<String, dynamic>.from(value)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertBudget(String userId, Budget budget) async {
    final items = await loadBudgets(userId);
    final index = items.indexWhere((item) => item.id == budget.id);
    if (index == -1) {
      items.add(budget);
    } else {
      items[index] = budget;
    }
    await saveBudgets(userId, items);
  }

  Future<void> removeBudget(String userId, String budgetId) async {
    final items = await loadBudgets(userId);
    items.removeWhere((item) => item.id == budgetId);
    await saveBudgets(userId, items);
  }

  Future<void> saveGoals(String userId, List<Goal> goals) async {
    final prefs = await _prefs;
    await prefs.setString(
      _key('goals', userId),
      jsonEncode(goals.map((goal) => goal.toJson()).toList()),
    );
  }

  Future<List<Goal>> loadGoals(String userId) async {
    final raw = (await _prefs).getString(_key('goals', userId));
    if (raw == null) return [];
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return values
          .map((value) => Goal.fromJson(Map<String, dynamic>.from(value)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertGoal(String userId, Goal goal) async {
    final items = await loadGoals(userId);
    final index = items.indexWhere((item) => item.id == goal.id);
    if (index == -1) {
      items.add(goal);
    } else {
      items[index] = goal;
    }
    await saveGoals(userId, items);
  }

  Future<void> removeGoal(String userId, String goalId) async {
    final items = await loadGoals(userId);
    items.removeWhere((item) => item.id == goalId);
    await saveGoals(userId, items);
  }
}
