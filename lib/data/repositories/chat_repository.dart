import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../core/utils/result.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class ChatRepository {
  final FirestoreService _fs;
  final NotificationRepository _notificationRepo;

  ChatRepository({
    FirestoreService? firestoreService,
    NotificationRepository? notificationRepo,
  }) : _fs = firestoreService ?? FirestoreService(),
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
      return Failure(
        e.message ?? 'Could not create chat room.',
        FirestoreException(e.code),
      );
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
        .map(
          (snap) => snap.docs.map((d) => ChatMessage.fromDocument(d)).toList(),
        );
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

      // Update chat room last-message metadata using set with merge
      // We also include the participants array so if this acts as a 'create'
      // it satisfies the firestore.rules requirement that the sender is in the array.
      final participantsUpdate = [message.senderId];
      if (message.receiverUid.isNotEmpty) {
        participantsUpdate.add(message.receiverUid);
      }
      batch.set(_fs.chatsCollection.doc(message.rideId), {
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
        'lastMessageText': message.text,
        'participants': FieldValue.arrayUnion(participantsUpdate),
      }, SetOptions(merge: true));

      debugPrint('[CHAT SEND] attempting write...');
      await batch.commit();
      debugPrint('[CHAT SEND] write successful');

      // Notify the other participant about the new message (fire-and-forget).
      if (message.receiverUid.isNotEmpty) {
        unawaited(
          _notificationRepo.createNotification(
            NotificationModel(
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
            ),
          ),
        );
      }

      return const Success(null);
    } on FirebaseException catch (e) {
      debugPrint('[CHAT SEND] ERROR: FirebaseException');
      debugPrint('[CHAT SEND] Firebase code: ${e.code}');
      debugPrint('[CHAT SEND] Firebase message: ${e.message}');
      return Failure(
        e.message ?? 'Failed to send message.',
        FirestoreException(e.code),
      );
    } catch (e) {
      debugPrint('[CHAT SEND] ERROR: Exception');
      debugPrint('[CHAT SEND] Firebase message: ${e.toString()}');
      return Failure('Unexpected error.', Exception(e.toString()));
    }
  }

  /// Soft-deletes a message by overwriting `isDeleted = true` and clearing text.
  Future<Result<void>> deleteMessage(String rideId, String messageId) async {
    try {
      await _messagesRef(
        rideId,
      ).doc(messageId).update({'isDeleted': true, 'text': ''});
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(
        e.message ?? 'Failed to delete message.',
        FirestoreException(e.code),
      );
    } catch (e) {
      return Failure('Unexpected error.', Exception(e.toString()));
    }
  }

  /// Marks a message as read by [uid].
  Future<void> markMessageRead(
    String rideId,
    String messageId,
    String uid,
  ) async {
    try {
      await _messagesRef(rideId).doc(messageId).update({'readBy.$uid': true});
    } catch (_) {}
  }

  Future<void> deleteChatRooms(List<String> rideIds) async {
    for (final rideId in rideIds) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        
        // 1. Delete all messages in the subcollection
        final msgsSnap = await _messagesRef(rideId).get();
        for (final doc in msgsSnap.docs) {
          batch.delete(doc.reference);
        }
        
        // 2. Delete the chat room document itself
        batch.delete(_fs.chatsCollection.doc(rideId));
        
        await batch.commit();
      } catch (e) {
        // Rethrow so the UI can catch it and display the error
        throw FirestoreException('Failed to delete chat $rideId: $e');
      }
    }
  }

  Future<void> markChatsAsRead(List<String> rideIds, String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final rideId in rideIds) {
      final snap = await _messagesRef(rideId).get();
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['senderId'] != uid) {
          final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
          if (readBy[uid] != true) {
            batch.update(doc.reference, {'readBy.$uid': true});
          }
        }
      }
    }
    try {
      await batch.commit();
    } catch (_) {}
  }

  Future<void> markChatsAsUnread(List<String> rideIds, String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final rideId in rideIds) {
      final snap = await _messagesRef(rideId)
          .orderBy('sentAt', descending: true)
          .limit(10)
          .get();
      
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['senderId'] != uid) {
          batch.update(doc.reference, {'readBy.$uid': false});
          break;
        }
      }
    }
    try {
      await batch.commit();
    } catch (_) {}
  }

  // ── Typing Indicator ──────────────────────────────────────────────────────

  /// Updates the typing status of the current user in the chat room.
  Future<void> setTyping(String rideId, String uid, bool isTyping) async {
    try {
      await _fs.chatsCollection.doc(rideId).update({'typing.$uid': isTyping});
    } catch (_) {}
  }
}
