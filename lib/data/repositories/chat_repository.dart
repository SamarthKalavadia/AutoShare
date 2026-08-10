import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../core/utils/result.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class ChatRepository {
  final FirestoreService _fs;
  final NotificationRepository _notificationRepo;

  ChatRepository({FirestoreService? firestoreService, NotificationRepository? notificationRepo})
      : _fs = firestoreService ?? FirestoreService(),
        _notificationRepo = notificationRepo ?? NotificationRepository();

  // ── Chat Room ─────────────────────────────────────────────────────────────

  /// Creates or merges a chat room document for the given ride.
  /// Uses SetOptions.merge so data is idempotent.
  Future<Result<void>> ensureChatRoom({
    required String rideId,
    required List<String> participants,
  }) async {
    try {
      final docRef = _fs.chatsCollection.doc(rideId);
      await docRef.set({
        'chatId': rideId,
        'rideId': rideId,
        'participants': participants,
        'typing': {},
        'lastMessageAt': null,
        'lastMessageText': '',
      }, SetOptions(merge: true));
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Could not create chat room.', FirestoreException(e.code));
    } catch (e) {
      return Failure('Unexpected error.', Exception(e.toString()));
    }
  }

  /// Streams a live snapshot of the chat room.
  Stream<ChatRoom?> streamChatRoom(String rideId) {
    return _fs.chatsCollection.doc(rideId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatRoom.fromDocument(doc);
    });
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  CollectionReference _messagesRef(String rideId) =>
      _fs.chatsCollection.doc(rideId).collection('messages');

  /// Streams all messages for a chat room, ordered by time ascending.
  Stream<List<ChatMessage>> streamMessages(String rideId) {
    return _messagesRef(rideId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromDocument(d)).toList());
  }

  /// Sends a new message to the chat room.
  Future<Result<void>> sendMessage(ChatMessage message) async {
    try {
      final colRef = _messagesRef(message.rideId);
      final docRef = colRef.doc();
      final withId = message.copyWith(messageId: docRef.id);
      final batch = FirebaseFirestore.instance.batch();

      // Write message doc
      batch.set(docRef, withId.toMap());

      // Update chat room last-message metadata
      batch.update(_fs.chatsCollection.doc(message.rideId), {
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
        'lastMessageText': message.text,
      });

      await batch.commit();

      // Notify the other participant about the new message (fire-and-forget).
      if (message.receiverUid.isNotEmpty) {
        unawaited(_notificationRepo.createNotification(NotificationModel(
          id: '',
          userId: message.receiverUid,
          title: 'New Message',
          body: message.text.length > 60
              ? '${message.text.substring(0, 60)}...'
              : message.text,
          type: 'chat',
          isRead: false,
          createdAt: DateTime.now(),
          relatedId: message.rideId,
        )));
      }

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to send message.', FirestoreException(e.code));
    } catch (e) {
      return Failure('Unexpected error.', Exception(e.toString()));
    }
  }

  /// Soft-deletes a message by overwriting `isDeleted = true` and clearing text.
  Future<Result<void>> deleteMessage(String rideId, String messageId) async {
    try {
      await _messagesRef(rideId).doc(messageId).update({
        'isDeleted': true,
        'text': '',
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to delete message.', FirestoreException(e.code));
    } catch (e) {
      return Failure('Unexpected error.', Exception(e.toString()));
    }
  }

  /// Marks a message as read by [uid].
  Future<void> markMessageRead(String rideId, String messageId, String uid) async {
    try {
      await _messagesRef(rideId).doc(messageId).update({
        'readBy.$uid': true,
      });
    } catch (_) {}
  }

  // ── Typing Indicator ──────────────────────────────────────────────────────

  /// Updates the typing status of the current user in the chat room.
  Future<void> setTyping(String rideId, String uid, bool isTyping) async {
    try {
      await _fs.chatsCollection.doc(rideId).update({
        'typing.$uid': isTyping,
      });
    } catch (_) {}
  }
}
