import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_service.dart';
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

  /// Creates a new notification document and dispatches push notification.
  Future<Result<void>> createNotification(
    NotificationModel notification,
  ) async {
    try {
      await _notifCollection.add(notification.toMap());

      // Trigger push notification to recipient's devices
      NotificationService().sendPushNotification(
        recipientUid: notification.userId,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        relatedId: notification.relatedId,
      );

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

  /// Marks multiple notifications as read.
  Future<Result<void>> markMultipleAsRead(
    String userId,
    List<String> notificationIds,
  ) async {
    if (notificationIds.isEmpty) return const Success(null);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in notificationIds) {
        batch.update(_notifCollection.doc(id), {'isRead': true});
      }
      await batch.commit();
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

  /// Marks multiple notifications as unread.
  Future<Result<void>> markMultipleAsUnread(
    String userId,
    List<String> notificationIds,
  ) async {
    if (notificationIds.isEmpty) return const Success(null);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in notificationIds) {
        batch.update(_notifCollection.doc(id), {'isRead': false});
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(
        e.message ?? 'Failed to mark as unread.',
        FirestoreException(e.code),
      );
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Permanently deletes multiple notifications.
  Future<Result<void>> deleteMultiple(
    String userId,
    List<String> notificationIds,
  ) async {
    if (notificationIds.isEmpty) return const Success(null);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in notificationIds) {
        batch.delete(_notifCollection.doc(id));
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(
        e.message ?? 'Failed to delete notifications.',
        FirestoreException(e.code),
      );
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }
}
