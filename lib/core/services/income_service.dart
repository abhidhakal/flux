import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:uuid/uuid.dart';
import '../models/income_model.dart';
import 'package:flutter/foundation.dart';

class IncomeService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Add Income
  Future<void> addIncome(Income income) async {
    try {
      debugPrint('🔵 INCOME SERVICE: Adding income');
      debugPrint('🔵 Amount: \$${income.amount}');

      // Ensure user document exists (reuse logic or simple check)
      // For now, we assume user exists or firestore handles it, but good practice to allow it
      
      final incomeId = income.id.isEmpty ? _uuid.v4() : income.id;
      final incomeToSave = income.copyWith(id: incomeId);

      await _firestore
          .collection('incomes')
          .doc(incomeId)
          .set(incomeToSave.toJson());

      debugPrint('✅ INCOME SERVICE: Income added successfully');

    } catch (e) {
      debugPrint('❌ INCOME SERVICE: Error adding income: $e');
      throw Exception('Failed to add income: $e');
    }
  }

  // Update Income
  Future<void> updateIncome(Income income) async {
    try {
      debugPrint('🔵 INCOME SERVICE: Updating income: ${income.id}');

      await _firestore
          .collection('incomes')
          .doc(income.id)
          .update(income.toJson());

      debugPrint('✅ INCOME SERVICE: Income updated successfully');
    } catch (e) {
      debugPrint('❌ INCOME SERVICE: Error updating income: $e');
      throw Exception('Failed to update income: $e');
    }
  }

  // Delete Income
  Future<void> deleteIncome(String incomeId) async {
    try {
      debugPrint('🔵 INCOME SERVICE: Deleting income: $incomeId');

      await _firestore
          .collection('incomes')
          .doc(incomeId)
          .delete();

      debugPrint('✅ INCOME SERVICE: Income deleted successfully');
    } catch (e) {
      debugPrint('❌ INCOME SERVICE: Error deleting income: $e');
      throw Exception('Failed to delete income: $e');
    }
  }

  // Get User Income
  Future<List<Income>> getUserIncome(String userId) async {
    try {
      debugPrint('🔵 INCOME SERVICE: Getting income for user: $userId');

      final querySnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      final incomes = querySnapshot.docs
          .map((doc) => Income.fromJson(doc.data()))
          .toList();

      debugPrint('✅ INCOME SERVICE: Found ${incomes.length} income records');
      return incomes;
    } catch (e) {
      debugPrint('❌ INCOME SERVICE: Error getting income: $e');
      return [];
    }
  }
}
