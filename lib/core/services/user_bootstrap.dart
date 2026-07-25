import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Ensures a minimal `users/{userId}` document exists before a service
/// writes data that references it (budgets/transactions/goals all do).
/// Never throws — a missing user doc shouldn't block the write that
/// triggered this check.
Future<void> ensureUserExists(FirebaseFirestore firestore, String userId,
    {String logTag = 'USER BOOTSTRAP'}) async {
  try {
    final userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      debugPrint('⚠️ $logTag: User not found, creating user document');
      await firestore.collection('users').doc(userId).set({
        'id': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    }
  } catch (e) {
    debugPrint('❌ $logTag: Error ensuring user exists: $e');
  }
}
