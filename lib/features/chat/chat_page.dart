import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:autoshare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoshare/features/chat/providers/chat_provider.dart';
import 'package:autoshare/features/chat/widgets/message_bubble.dart';
import 'package:autoshare/features/chat/widgets/ride_summary_banner.dart';

class ChatPage extends ConsumerStatefulWidget {
  final ChatPageArgs args;

  const ChatPage({super.key, required this.args});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  late final String _rideId;

  @override
  void initState() {
    super.initState();
    _rideId = widget.args.ride.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).init(
        _rideId,
        receiverUid: widget.args.otherParticipantUid,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(max,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        } else {
          _scrollController.jumpTo(max);
        }
      }
    });
  }

  Future<void> _send() async {
    final sent = await ref.read(chatProvider.notifier).sendMessage();
    _controller.clear();
    if (sent) _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final blackColor = theme.colorScheme.onSurface;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);

    final currentUid = ref.watch(authControllerProvider).value?.uid ?? '';
    final chatInput = ref.watch(chatProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(_rideId));
    final chatRoomAsync = ref.watch(chatRoomProvider(_rideId));

    final typingUids = chatRoomAsync.whenData((room) {
      if (room == null) return <String>[];
      return room.typing.entries
          .where((e) => e.value && e.key != currentUid)
          .map((e) => e.key)
          .toList();
    }).value ?? [];

    ref.watch(chatRoomInitProvider((
      rideId: _rideId,
      participants: [currentUid, widget.args.otherParticipantUid],
    )));

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: blackColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: borderColor,
              child: Text(
                widget.args.otherParticipantName.isNotEmpty
                    ? widget.args.otherParticipantName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: blackColor),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.args.otherParticipantName,
                    style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: blackColor)),
                if (typingUids.isNotEmpty)
                  Text('typing...',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: primaryColor,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: Column(
        children: [
          RideSummaryBanner(ride: widget.args.ride),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 64, color: Color(0xFFEAE5DD)),
                        const SizedBox(height: 16),
                        Text('No messages yet.\nSay hello! 👋',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: mutedText)),
                      ],
                    ),
                  );
                }

                _scrollToBottom(animated: false);

                for (final m in messages.reversed) {
                  if (!m.isDeleted &&
                      m.senderId != currentUid &&
                      !m.isReadBy(currentUid)) {
                    ref.read(chatProvider.notifier).markRead(m.messageId);
                    break;
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final prev = i > 0 ? messages[i - 1] : null;
                    final showDate = prev == null ||
                        !_isSameDay(prev.sentAt, msg.sentAt);
                    final isGrouped = prev != null &&
                        prev.senderId == msg.senderId &&
                        msg.sentAt.difference(prev.sentAt).inSeconds < 60 &&
                        !showDate;
                    return Column(
                      children: [
                        if (showDate) _DateSeparator(date: msg.sentAt),
                        MessageBubble(
                          message: msg,
                          showSenderName: !isGrouped,
                          isGrouped: isGrouped,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => Center(
                  child: CircularProgressIndicator(color: primaryColor)),
              error: (e, _) => Center(
                  child: Text('Failed to load messages',
                      style: GoogleFonts.inter())),
            ),
          ),
          if (typingUids.isNotEmpty) const _TypingIndicator(),
          _ChatInputBar(
            controller: _controller,
            focusNode: _focusNode,
            isSending: chatInput.isSending,
            onChanged: (t) =>
                ref.read(chatProvider.notifier).updateText(t),
            onSend: _send,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Date Separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFEAE5DD))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFEAE5DD),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6F6F72))),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFEAE5DD))),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _anim,
                builder: (_, child) {
                  final delay = i * 0.2;
                  final val =
                      ((_anim.value - delay).clamp(0.0, 0.6) / 0.6);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8 + val * 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF6C000),
                        borderRadius: BorderRadius.circular(4)),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Chat Input Bar ────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF6C000);
    const blackColor = Color(0xFF121212);
    const borderColor = Color(0xFFEAE5DD);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 24,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(fontSize: 15, color: blackColor),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle:
                      GoogleFonts.inter(color: const Color(0xFFAAAAAA)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSending ? borderColor : primaryColor,
              shape: BoxShape.circle,
            ),
            child: isSending
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF121212)),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded,
                        color: blackColor, size: 22),
                  ),
          ),
        ],
      ),
    );
  }
}
