import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/services/firestore_service.dart';
import '../models/notification_model.dart';

/// Repository for all notification Firestore operations.
/// Notifications are stored in the top-level `notifications` collection.
class NotificationRepository {
  final FirestoreService _firestoreService;

  NotificationRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  CollectionReference<Object?> get _notifCollection =>
      _firestoreService.notificationsCollection;

  /// Streams real-time notifications for [userId], ordered newest first.
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _notifCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map(
                (d) => NotificationModel.fromDocument(
                  d as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) => <NotificationModel>[]);
  }

  /// Creates a new notification document.
  Future<Result<void>> createNotification(
    NotificationModel notification,
  ) async {
    try {
      await _notifCollection.add(notification.toMap());
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(
        e.message ?? 'Failed to create notification.',
        FirestoreException(e.code),
      );
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Marks a single notification as read.
  Future<Result<void>> markAsRead(String userId, String notificationId) async {
    try {
      // Security: Could verify the notification belongs to the user, but rules should handle this.
      await _notifCollection.doc(notificationId).update({'isRead': true});
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(
        e.message ?? 'Failed to mark as read.',
        FirestoreException(e.code),
      );
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Marks all unread notifications as read in a batch.
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notifCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      if (snapshot.docs.isEmpty) return const Success(null);

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(
        e.message ?? 'Failed to mark all as read.',
        FirestoreException(e.code),
      );
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Permanently deletes a notification.
  Future<Result<void>> deleteNotification(
    String userId,
    String notificationId,
  ) async {
    try {
      await _notifCollection.doc(notificationId).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(
        e.message ?? 'Failed to delete notification.',
        FirestoreException(e.code),
      );
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }
}
