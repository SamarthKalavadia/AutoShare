import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:autoshare/core/utils/result.dart';
import 'package:autoshare/data/models/chat_model.dart';
import 'package:autoshare/data/models/ride_model.dart';
import 'package:autoshare/data/models/user_model.dart';
import 'package:autoshare/shared/providers.dart';
import 'package:autoshare/features/auth/presentation/controllers/auth_controller.dart';

// ── Chat Room Init ────────────────────────────────────────────────────────────

final chatRoomInitProvider = FutureProvider.family<void, ({String rideId, String participantIds})>(
  (ref, args) async {
    final participants = args.participantIds.split(',').where((id) => id.isNotEmpty).toList();
    await ref.read(chatRepositoryProvider).ensureChatRoom(
      rideId: args.rideId,
      participants: participants,
    );
  },
);

// ── Messages Stream ───────────────────────────────────────────────────────────

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
      (ref, rideId) => ref.watch(chatRepositoryProvider).streamMessages(rideId),
    );

// ── Chat Room Stream ──────────────────────────────────────────────────────────

final chatRoomProvider = StreamProvider.autoDispose.family<ChatRoom?, String>(
  (ref, rideId) => ref.watch(chatRepositoryProvider).streamChatRoom(rideId),
);

// ── Chat User ─────────────────────────────────────────────────────────────────

final chatUserProvider = FutureProvider.autoDispose.family<UserModel?, String>((ref, uid) async {
  if (uid.isEmpty) return null;
  final result = await ref.watch(userRepositoryProvider).getUser(uid);
  if (result is Success<UserModel>) {
    return result.data;
  }
  return null;
});

// ── Live User Chats Stream ──────────────────────────────────────────────────

final userChatsStreamProvider = StreamProvider.autoDispose<List<ChatRoom>>((ref) {
  final uid = ref.watch(authControllerProvider).value?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).streamUserChats(uid);
});

// ── Multi-selection Chat List Actions ───────────────────────────────────────

class ChatsListActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> deleteMultiple(List<String> rideIds) async {
    await ref.read(chatRepositoryProvider).deleteChatRooms(rideIds);
  }

  Future<void> markMultipleAsRead(List<String> rideIds) async {
    final uid = ref.read(authControllerProvider).value?.uid;
    if (uid == null) return;
    await ref.read(chatRepositoryProvider).markChatsAsRead(rideIds, uid);
  }

  Future<void> markMultipleAsUnread(List<String> rideIds) async {
    final uid = ref.read(authControllerProvider).value?.uid;
    if (uid == null) return;
    await ref.read(chatRepositoryProvider).markChatsAsUnread(rideIds, uid);
  }
}

final chatsListActionsProvider = NotifierProvider<ChatsListActionsNotifier, void>(
  ChatsListActionsNotifier.new,
);

// ── Chat Input State ─────────────────────────────────────────────────────────

class ChatInputState {
  final String text;
  final bool isSending;
  const ChatInputState({this.text = '', this.isSending = false});
  ChatInputState copyWith({String? text, bool? isSending}) => ChatInputState(
    text: text ?? this.text,
    isSending: isSending ?? this.isSending,
  );
}

class ChatNotifier extends Notifier<ChatInputState> {
  Timer? _typingTimer;
  String? _rideId;

  String get _uid => ref.read(authControllerProvider).value?.uid ?? '';
  String? _receiverUid;

  @override
  ChatInputState build() {
    ref.onDispose(() {
      _typingTimer?.cancel();
      _setTyping(false);
    });
    return const ChatInputState();
  }

  void init(String rideId, {String receiverUid = ''}) {
    _rideId = rideId;
    _receiverUid = receiverUid;
  }

  void _setTyping(bool isTyping) {
    if (_rideId == null) return;
    ref.read(chatRepositoryProvider).setTyping(_rideId!, _uid, isTyping);
  }

  void updateText(String text) {
    state = state.copyWith(text: text);
    _setTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () => _setTyping(false));
  }

  Future<bool> sendMessage() async {
    if (_rideId == null || _rideId!.isEmpty) return false;
    final text = state.text.trim();
    if (text.isEmpty) return false;

    state = ChatInputState(text: text, isSending: true);

    try {
      final user = ref.read(authControllerProvider).value;
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? user?.uid;
      if (currentUid == null || currentUid.isEmpty) {
        debugPrint('[CHAT SEND] ERROR: User not authenticated');
        state = ChatInputState(text: text, isSending: false);
        return false;
      }

      final senderName = (user?.name.isNotEmpty == true)
          ? user!.name
          : (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
              ? FirebaseAuth.instance.currentUser!.displayName!
              : 'User');

      var targetReceiverUid = _receiverUid ?? '';
      if (targetReceiverUid.isEmpty) {
        final chatRoom = ref.read(chatRoomProvider(_rideId!)).value;
        if (chatRoom != null && chatRoom.participants.isNotEmpty) {
          targetReceiverUid = chatRoom.participants.firstWhere(
            (p) => p != currentUid,
            orElse: () => '',
          );
        }
      }
      
      debugPrint('[CHAT SEND] currentUserUid: $currentUid');
      debugPrint('[CHAT SEND] conversationId: $_rideId');
      debugPrint('[CHAT SEND] recipientUid: $targetReceiverUid');
      debugPrint('[CHAT SEND] message: $text');
      debugPrint('[CHAT SEND] firestorePath: chats/$_rideId/messages');

      final message = ChatMessage.create(
        rideId: _rideId!,
        senderId: currentUid,
        senderName: senderName,
        receiverUid: targetReceiverUid,
        text: text,
      );

      final result = await ref.read(chatRepositoryProvider).sendMessage(message);

      if (result is Success) {
        state = const ChatInputState();
        return true;
      } else {
        state = ChatInputState(text: text, isSending: false);
        return false;
      }
    } catch (e) {
      debugPrint('[CHAT SEND] ERROR: Unexpected exception: $e');
      state = ChatInputState(text: text, isSending: false);
      return false;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_rideId == null) return;
    await ref.read(chatRepositoryProvider).deleteMessage(_rideId!, messageId);
  }

  Future<void> markRead(String messageId) async {
    if (_rideId == null) return;
    await ref
        .read(chatRepositoryProvider)
        .markMessageRead(_rideId!, messageId, _uid);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatInputState>(
  ChatNotifier.new,
);

// ── Chat Page Args ────────────────────────────────────────────────────────────

class ChatPageArgs {
  final RideModel ride;
  final String otherParticipantUid;
  final String otherParticipantName;

  const ChatPageArgs({
    required this.ride,
    required this.otherParticipantUid,
    required this.otherParticipantName,
  });
}
