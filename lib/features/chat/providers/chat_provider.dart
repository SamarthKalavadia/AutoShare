import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:autoshare/core/utils/result.dart';
import 'package:autoshare/data/models/chat_model.dart';
import 'package:autoshare/data/models/ride_model.dart';
import 'package:autoshare/shared/providers.dart';
import 'package:autoshare/features/auth/presentation/controllers/auth_controller.dart';

// ── Chat Room Init ────────────────────────────────────────────────────────────

final chatRoomInitProvider = FutureProvider.autoDispose
    .family<void, ({String rideId, List<String> participants})>((
      ref,
      args,
    ) async {
      final repo = ref.watch(chatRepositoryProvider);
      await repo.ensureChatRoom(
        rideId: args.rideId,
        participants: args.participants,
      );
    });

// ── Messages Stream ───────────────────────────────────────────────────────────

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
      (ref, rideId) => ref.watch(chatRepositoryProvider).streamMessages(rideId),
    );

// ── Chat Room Stream ──────────────────────────────────────────────────────────

final chatRoomProvider = StreamProvider.autoDispose.family<ChatRoom?, String>(
  (ref, rideId) => ref.watch(chatRepositoryProvider).streamChatRoom(rideId),
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
  String get _name => ref.read(authControllerProvider).value?.name ?? 'User';
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
    if (_rideId == null) return false;
    final text = state.text.trim();
    if (text.isEmpty) return false;

    state = state.copyWith(isSending: true, text: '');
    _typingTimer?.cancel();
    _setTyping(false);

    final message = ChatMessage.create(
      rideId: _rideId!,
      senderId: _uid,
      senderName: _name,
      receiverUid: _receiverUid ?? '',
      text: text,
    );

    final result = await ref.read(chatRepositoryProvider).sendMessage(message);
    state = state.copyWith(isSending: false);
    return result is Success;
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
