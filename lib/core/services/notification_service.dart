import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;

  // Create a notification
  Future<void> createNotification(Notification notification) async {
    try {
      final notificationRef =
          _firestore.collection('notifications').doc(notification.id);
      await notificationRef.set(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Most recent notifications shown to the user; older history is pruned
  // (see pruneOldNotifications) so this is also a practical safety cap.
  static const int notificationFetchLimit = 100;

  // Get user notifications
  Future<List<Notification>> getUserNotifications(String userId) async {
    try {
      // Keep this query to a single equality filter. Ordering by createdAt
      // requires a composite Firestore index and made the notifications page
      // wait/fail on projects where that index was not deployed.
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .limit(notificationFetchLimit)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => Notification.fromJson(doc.data()))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      debugPrint(
          '❌ NOTIFICATION SERVICE: Error getting user notifications: $e');
      return [];
    }
  }

  // Get unread notifications
  Future<List<Notification>> getUnreadNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.name)
          .get();

      return querySnapshot.docs
          .map((doc) => Notification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint(
          '❌ NOTIFICATION SERVICE: Error getting unread notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final notificationRef =
          _firestore.collection('notifications').doc(notificationId);
      await notificationRef.update({
        'status': NotificationStatus.read.name,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Dismiss notification
  Future<void> dismissNotification(String notificationId) async {
    try {
      final notificationRef =
          _firestore.collection('notifications').doc(notificationId);
      await notificationRef.update({
        'status': NotificationStatus.dismissed.name,
        'dismissedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to dismiss notification: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final notificationRef =
          _firestore.collection('notifications').doc(notificationId);
      await notificationRef.delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete read/dismissed notifications older than [maxAge] so the
  // collection (and the fetch in getUserNotifications) doesn't grow
  // unbounded over the life of an account. Unread notifications are kept
  // regardless of age.
  Future<void> pruneOldNotifications(String userId,
      {Duration maxAge = const Duration(days: 30)}) async {
    try {
      final cutoff = DateTime.now().subtract(maxAge).toIso8601String();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final stale = querySnapshot.docs.where((doc) {
        final data = doc.data();
        if (data['status'] == NotificationStatus.unread.name) return false;
        final createdAt = data['createdAt'] as String?;
        return createdAt != null && createdAt.compareTo(cutoff) < 0;
      });

      if (stale.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in stale) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint(
          '✅ NOTIFICATION SERVICE: Pruned ${stale.length} old notifications');
    } catch (e) {
      debugPrint('❌ NOTIFICATION SERVICE: Error pruning old notifications: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.name)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.name,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }
}
