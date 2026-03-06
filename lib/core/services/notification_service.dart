import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class NotificationService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a notification
  Future<void> createNotification(Notification notification) async {
    try {
      final notificationRef = _firestore.collection('notifications').doc(notification.id);
      await notificationRef.set(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get user notifications
  Future<List<Notification>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Notification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error getting user notifications: $e');
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
      print('❌ NOTIFICATION SERVICE: Error getting unread notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final notificationRef = _firestore.collection('notifications').doc(notificationId);
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
      final notificationRef = _firestore.collection('notifications').doc(notificationId);
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
      final notificationRef = _firestore.collection('notifications').doc(notificationId);
      await notificationRef.delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
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

  // --- PRIVATE GENERATION METHODS (DEPRECATED) ---

  // Generate unique ID
  String generateId() {
    return _uuid.v4();
  }

  // Get last smart notification generation time
  Future<DateTime?> _getLastSmartNotificationGeneration(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final lastGenerated = data['lastSmartNotificationGeneration'];
        if (lastGenerated != null) {
          return DateTime.parse(lastGenerated);
        }
      }
      return null;
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error getting last generation time: $e');
      return null;
    }
  }

  // Check if smart notifications can be generated (not within cooldown period)
  Future<bool> canGenerateSmartNotifications(String userId) async {
    try {
      final lastGenerated = await _getLastSmartNotificationGeneration(userId);
      if (lastGenerated == null) return true;
      
      final timeSinceLastGeneration = DateTime.now().difference(lastGenerated);
      return timeSinceLastGeneration.inHours >= 1;
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error checking generation eligibility: $e');
      return true; // Allow generation if there's an error
    }
  }

  // Update last smart notification generation time (Now public for use by triggers/background tasks)
  Future<void> updateLastSmartNotificationGeneration(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'lastSmartNotificationGeneration': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error updating last generation time: $e');
    }
  }

  // Get time until next generation is allowed
  Future<Duration?> getTimeUntilNextGeneration(String userId) async {
    try {
      final lastGenerated = await _getLastSmartNotificationGeneration(userId);
      if (lastGenerated == null) return null;
      
      final timeSinceLastGeneration = DateTime.now().difference(lastGenerated);
      if (timeSinceLastGeneration.inHours >= 1) return null;
      
      return Duration(minutes: 60 - timeSinceLastGeneration.inMinutes);
    } catch (e) {
      print('❌ NOTIFICATION SERVICE: Error getting time until next generation: $e');
      return null;
    }
  }
}
