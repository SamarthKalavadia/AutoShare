import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../models/notification_model.dart';

/// Repository for all notification Firestore operations.
/// Notifications are stored in `users/{userId}/notifications`.
class NotificationRepository {
  final FirebaseFirestore _db;

  NotificationRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifCollection(String userId) {
    return _db.collection('users').doc(userId).collection('notifications');
  }

  /// Streams real-time notifications for [userId], ordered newest first.
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _notifCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => NotificationModel.fromDocument(d)).toList());
  }

  /// Creates a new notification document in the recipient's sub-collection.
  Future<Result<void>> createNotification(NotificationModel notification) async {
    try {
      await _notifCollection(notification.userId).add(notification.toMap());
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to create notification.', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Marks a single notification as read.
  Future<Result<void>> markAsRead(String userId, String notificationId) async {
    try {
      await _notifCollection(userId).doc(notificationId).update({'isRead': true});
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to mark as read.', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Marks all unread notifications as read in a batch.
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notifCollection(userId)
          .where('isRead', isEqualTo: false)
          .get();
      if (snapshot.docs.isEmpty) return const Success(null);

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to mark all as read.', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Permanently deletes a notification.
  Future<Result<void>> deleteNotification(
      String userId, String notificationId) async {
    try {
      await _notifCollection(userId).doc(notificationId).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to delete notification.',
          FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }
}
