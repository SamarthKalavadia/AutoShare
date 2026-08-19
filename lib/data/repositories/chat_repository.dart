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

  /// Streams all chat rooms where [uid] is a participant, ordered by last message time descending.
  Stream<List<ChatRoom>> streamUserChats(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _fs.chatsCollection
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final rooms = snap.docs.map((d) => ChatRoom.fromDocument(d)).toList();
          rooms.sort((a, b) {
            final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return rooms;
        })
        .handleError((error) {
          debugPrint('[USER CHATS STREAM ERROR]: $error');
          return <ChatRoom>[];
        });
  }

  /// Streams a live snapshot of the chat room.
  Stream<ChatRoom?> streamChatRoom(String rideId) {
    return _fs.chatsCollection
        .doc(rideId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return ChatRoom.fromDocument(doc);
        })
        .handleError((error) {
          debugPrint('[CHAT ROOM STREAM ERROR]: $error');
          return null;
        });
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  CollectionReference _messagesRef(String rideId) =>
      _fs.chatsCollection.doc(rideId).collection('messages');

  /// Streams all messages for a chat room, ordered by time ascending.
  Stream<List<ChatMessage>> streamMessages(String rideId) {
    return _fs.messagesCollection
        .where('rideId', isEqualTo: rideId)
        .snapshots()
        .map((snap) {
          final msgs = snap.docs.map((d) => ChatMessage.fromDocument(d)).toList();
          msgs.sort((a, b) => a.sentAt.compareTo(b.sentAt));
          return msgs;
        })
        .handleError((error) {
          debugPrint('[MESSAGES ROOT STREAM ERROR]: $error');
          return <ChatMessage>[];
        });
  }

  /// Sends a new message to the chat room.
  Future<Result<void>> sendMessage(ChatMessage message) async {
    try {
      final rootDocRef = _fs.messagesCollection.doc();
      final withId = message.copyWith(messageId: rootDocRef.id);

      final participantsUpdate = [message.senderId];
      if (message.receiverUid.isNotEmpty && message.receiverUid != message.senderId) {
        participantsUpdate.add(message.receiverUid);
      }

      // 1. Write to root messages collection (matches deployed Firebase security rules)
      await rootDocRef.set(withId.toMap());

      // 2. Also write to subcollection in try-catch for dual compatibility
      try {
        await _messagesRef(message.rideId).doc(rootDocRef.id).set(withId.toMap());
      } catch (e) {
        debugPrint('[SUBCOLLECTION WRITE SKIPPED]: $e');
      }

      // 3. Update top-level chat room document with latest message info
      try {
        await _fs.chatsCollection.doc(message.rideId).set({
          'chatId': message.rideId,
          'rideId': message.rideId,
          'participants': FieldValue.arrayUnion(participantsUpdate),
          'lastMessageAt': Timestamp.fromDate(message.sentAt),
          'lastMessageText': message.text,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[CHAT DOC UPDATE SKIPPED]: $e');
      }

      debugPrint('[CHAT SEND] Message sent successfully: ${rootDocRef.id}');

      // 4. Resolve all recipients (all participants in the conversation except sender)
      final recipients = <String>{};
      if (message.receiverUid.isNotEmpty && message.receiverUid != message.senderId) {
        recipients.add(message.receiverUid);
      }

      try {
        final chatDoc = await _fs.chatsCollection.doc(message.rideId).get();
        if (chatDoc.exists) {
          final data = chatDoc.data() as Map<String, dynamic>?;
          final participants = List<String>.from(data?['participants'] ?? []);
          for (final p in participants) {
            if (p.isNotEmpty && p != message.senderId) {
              recipients.add(p);
            }
          }
        }
      } catch (e) {
        debugPrint('[CHAT PARTICIPANTS LOOKUP ERROR]: $e');
      }

      // If still empty, check the ride document
      if (recipients.isEmpty) {
        try {
          final rideDoc = await _fs.ridesCollection.doc(message.rideId).get();
          if (rideDoc.exists) {
            final data = rideDoc.data() as Map<String, dynamic>?;
            final driverId = data?['driverId'] as String? ?? '';
            if (driverId.isNotEmpty && driverId != message.senderId) {
              recipients.add(driverId);
            }
          }
        } catch (_) {}
      }

      // 5. Fire-and-forget push notification to each recipient
      final notifTitle = message.senderName.isNotEmpty ? message.senderName : 'New Message';
      final notifBody = message.text.length > 80
          ? '${message.text.substring(0, 80)}...'
          : message.text;

      for (final recipientUid in recipients) {
        unawaited(
          _notificationRepo.createNotification(
            NotificationModel(
              id: '',
              userId: recipientUid,
              title: notifTitle,
              body: notifBody,
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
      debugPrint('[CHAT SEND] FirebaseException (${e.code}): ${e.message}');
      return Failure(
        e.message ?? 'Failed to send message.',
        FirestoreException(e.code),
      );
    } catch (e) {
      debugPrint('[CHAT SEND] Unexpected exception: $e');
      return Failure('Unexpected error.', Exception(e.toString()));
    }
  }

  /// Soft-deletes a message by overwriting `isDeleted = true` and clearing text.
  Future<Result<void>> deleteMessage(String rideId, String messageId) async {
    try {
      await _fs.messagesCollection.doc(messageId).update({'isDeleted': true, 'text': ''});
      try {
        await _messagesRef(rideId).doc(messageId).update({'isDeleted': true, 'text': ''});
      } catch (_) {}
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
      await _fs.messagesCollection.doc(messageId).update({'readBy.$uid': true});
      try {
        await _messagesRef(rideId).doc(messageId).update({'readBy.$uid': true});
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> deleteChatRooms(List<String> rideIds) async {
    for (final rideId in rideIds) {
      try {
        final rootMsgs = await _fs.messagesCollection.where('rideId', isEqualTo: rideId).get();
        for (final doc in rootMsgs.docs) {
          await doc.reference.delete();
        }
        try {
          final msgsSnap = await _messagesRef(rideId).get();
          for (final doc in msgsSnap.docs) {
            await doc.reference.delete();
          }
        } catch (_) {}
        await _fs.chatsCollection.doc(rideId).delete();
      } catch (e) {
        throw FirestoreException('Failed to delete chat $rideId: $e');
      }
    }
  }

  Future<void> markChatsAsRead(List<String> rideIds, String uid) async {
    for (final rideId in rideIds) {
      final snap = await _fs.messagesCollection.where('rideId', isEqualTo: rideId).get();
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['senderId'] != uid) {
          final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
          if (readBy[uid] != true) {
            await doc.reference.update({'readBy.$uid': true});
          }
        }
      }
    }
  }

  Future<void> markChatsAsUnread(List<String> rideIds, String uid) async {
    for (final rideId in rideIds) {
      final snap = await _fs.messagesCollection
          .where('rideId', isEqualTo: rideId)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['senderId'] != uid) {
          await doc.reference.update({'readBy.$uid': false});
          break;
        }
      }
    }
  }

  // ── Typing Indicator ──────────────────────────────────────────────────────

  /// Updates the typing status of the current user in the chat room.
  Future<void> setTyping(String rideId, String uid, bool isTyping) async {
    try {
      await _fs.chatsCollection.doc(rideId).update({'typing.$uid': isTyping});
    } catch (_) {}
  }
}
