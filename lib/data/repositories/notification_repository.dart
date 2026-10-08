import 'dart:async';
import 'package:flutter/foundation.dart';
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
    // 1. Immediately trigger high-priority push notification asynchronously without blocking caller
    unawaited(
      NotificationService().sendPushNotification(
        recipientUid: notification.userId,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        relatedId: notification.relatedId,
      ).catchError((e) {
        debugPrint('[NotificationRepository] push dispatch note: $e');
      }),
    );

    // 2. Persist in-app notification document in Firestore
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

  /// Queues a push notification for the Node.js FCM worker (server/notification_worker.js)
  /// and writes corresponding in-app notification records in Firestore.
  Future<Result<void>> queuePushNotification({
    required List<String> recipientUids,
    required String title,
    required String body,
    required String type,
    String? relatedId,
    Map<String, dynamic>? dataPayload,
  }) async {
    final uniqueRecipients = recipientUids
        .where((u) => u.trim().isNotEmpty)
        .toSet()
        .toList();
    if (uniqueRecipients.isEmpty) return const Success(null);

    try {
      // 1. Persist in-app notifications in batch
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      for (final uid in uniqueRecipients) {
        final docRef = _notifCollection.doc();
        batch.set(docRef, {
          'userId': uid,
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'createdAt': Timestamp.fromDate(now),
          if (relatedId != null) 'relatedId': relatedId,
        });
      }
      await batch.commit();

      // 2. Queue for FCM Worker in push_notifications collection (if cloud rules permit)
      try {
        final queuePayload = <String, dynamic>{
          'recipientUids': uniqueRecipients,
          'title': title,
          'body': body,
          'type': type,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          if (relatedId != null) 'relatedId': relatedId,
          if (dataPayload != null) 'data': dataPayload,
        };

        await FirebaseFirestore.instance
            .collection('push_notifications')
            .add(queuePayload);

        debugPrint(
          '[NotificationRepository] Queued push notification for ${uniqueRecipients.length} recipients: $title',
        );
      } catch (queueErr) {
        debugPrint(
          '[NotificationRepository] Note: push_notifications write bypassed; notifications collection is active: $queueErr',
        );
      }
      return const Success(null);
    } catch (e) {
      debugPrint('[NotificationRepository] queuePushNotification error: $e');
      return Failure(
        'Failed to queue push notification.',
        Exception(e.toString()),
      );
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
