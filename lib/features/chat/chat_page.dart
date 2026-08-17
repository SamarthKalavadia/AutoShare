import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:autoshare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoshare/features/chat/providers/chat_provider.dart';
import 'package:autoshare/features/chat/widgets/message_bubble.dart';
import 'package:autoshare/features/chat/widgets/ride_summary_banner.dart';
import 'package:autoshare/shared/utils/avatar_utils.dart';
import 'package:autoshare/shared/providers.dart';

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
  bool _showScrollBtn = false;

  late final String _rideId;

  @override
  void initState() {
    super.initState();
    _rideId = widget.args.ride.id;
    
    // Debug Logs for diagnosing Chat Data Flow
    debugPrint('[CHAT DEBUG] currentUserUid: ${FirebaseAuth.instance.currentUser?.uid}');
    debugPrint('[CHAT DEBUG] selectedChatId: $_rideId');
    debugPrint('[CHAT DEBUG] conversationId: $_rideId');
    debugPrint('[CHAT DEBUG] otherParticipantUid: ${widget.args.otherParticipantUid}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatProvider.notifier)
          .init(_rideId, receiverUid: widget.args.otherParticipantUid);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty && widget.args.otherParticipantUid.isNotEmpty) {
        // Fire and forget chat room initialization to prevent UI blocking
        ref.read(chatRepositoryProvider).ensureChatRoom(
          rideId: _rideId,
          participants: [uid, widget.args.otherParticipantUid],
        ).then((_) {
          debugPrint('[CHAT DEBUG] ensureChatRoom completed successfully');
        }).catchError((e) {
          debugPrint('[CHAT DEBUG] ensureChatRoom error: $e');
        });
      }
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      final show = position.maxScrollExtent - position.pixels > 150;
      if (show != _showScrollBtn) {
        setState(() => _showScrollBtn = show);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true, bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        
        // If user is scrolled up significantly, don't auto-scroll unless forced
        if (!force && position.maxScrollExtent - position.pixels > 150) {
          return;
        }

        final max = position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(max);
        }
      }
    });
  }

  Future<void> _send() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated. Please log in.')),
        );
      }
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).updateText(text);
    
    final sent = await ref.read(chatProvider.notifier).sendMessage();
    
    if (sent) {
      _scrollToBottom(force: true);
    } else {
      if (mounted) {
        _controller.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message couldn\'t be sent. Please try again.')),
        );
      }
    }
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
    final appBarBg = theme.scaffoldBackgroundColor;

    final currentUid = ref.watch(authControllerProvider).value?.uid ?? '';
    final chatInput = ref.watch(chatProvider);
    
    final chatRoomAsync = ref.watch(chatRoomProvider(_rideId));
    final resolvedOtherUid = widget.args.otherParticipantUid.isNotEmpty
        ? widget.args.otherParticipantUid
        : (chatRoomAsync.value?.participants.firstWhere(
            (p) => p != currentUid,
            orElse: () => '',
          ) ?? '');

    final otherUserAsync = ref.watch(chatUserProvider(resolvedOtherUid));
    
    final participantName = otherUserAsync.when(
      data: (user) {
        if (user != null && user.name.isNotEmpty) return user.name;
        if (widget.args.otherParticipantName.isNotEmpty) return widget.args.otherParticipantName;
        return 'User';
      },
      loading: () => widget.args.otherParticipantName.isNotEmpty
          ? widget.args.otherParticipantName
          : 'Loading...',
      error: (_, __) => widget.args.otherParticipantName.isNotEmpty
          ? widget.args.otherParticipantName
          : 'User',
    );
    final participantAvatar = otherUserAsync.value?.profileImage;

    final messagesAsync = ref.watch(chatMessagesProvider(_rideId));

    final typingUids = chatRoomAsync.value?.typing.entries
        .where((e) => e.value && e.key != currentUid)
        .map((e) => e.key)
        .toList() ?? [];

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: blackColor, size: 24),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.only(left: 8),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            () {
              final avatarProvider = getAvatarImageProvider(participantAvatar);
              return Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEAE5DD),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: avatarProvider != null
                      ? DecorationImage(
                          image: avatarProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: avatarProvider == null
                    ? Text(
                        participantName.isNotEmpty ? participantName[0].toUpperCase() : '?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: blackColor,
                        ),
                      )
                    : null,
              );
            }(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participantName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: blackColor,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    typingUids.isNotEmpty ? 'typing...' : 'Ride partner',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: typingUids.isNotEmpty ? primaryColor : (isDark ? Colors.white54 : const Color(0xFF8E8E93)),
                      fontStyle: typingUids.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                      fontWeight: typingUids.isNotEmpty ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1, 
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFEF),
          ),
        ),
      ),
      body: Column(
        children: [
          RideSummaryBanner(ride: widget.args.ride),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                debugPrint('[CHAT DEBUG] message snapshot received');
                debugPrint('[CHAT DEBUG] message count: ${messages.length}');
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        () {
                          final avatarProvider = getAvatarImageProvider(participantAvatar);
                          return Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEAE5DD),
                              image: avatarProvider != null
                                  ? DecorationImage(image: avatarProvider, fit: BoxFit.cover)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: avatarProvider == null
                                ? Text(
                                    participantName.isNotEmpty ? participantName[0].toUpperCase() : '?',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: blackColor,
                                    ),
                                  )
                                : null,
                          );
                        }(),
                        Text(
                          'Start a conversation with $participantName',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Send a message about your ride.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: mutedText),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom(animated: false);

                for (final m in messages.reversed) {
                  if (!m.isDeleted && m.senderId != currentUid && !m.isReadBy(currentUid)) {
                    ref.read(chatProvider.notifier).markRead(m.messageId);
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final prev = i > 0 ? messages[i - 1] : null;
                    final showDate = prev == null || !_isSameDay(prev.sentAt, msg.sentAt);
                    final isGrouped = prev != null &&
                        prev.senderId == msg.senderId &&
                        msg.sentAt.difference(prev.sentAt).inMinutes < 5 &&
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
              loading: () {
                debugPrint('[CHAT DEBUG] message stream started / loading');
                return Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: primaryColor,
                    ),
                  ),
                );
              },
              error: (e, stack) {
                debugPrint('[CHAT DEBUG] stream error: $e');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Couldn\'t load this conversation.', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(chatMessagesProvider(_rideId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (typingUids.isNotEmpty) const _TypingIndicator(),
          if (_showScrollBtn)
            GestureDetector(
              onTap: () => _scrollToBottom(force: true),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 50 : 20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New message',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: isDark ? Colors.white : primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          _ChatInputBar(
            controller: _controller,
            focusNode: _focusNode,
            isSending: chatInput.isSending,
            onChanged: (t) => ref.read(chatProvider.notifier).updateText(t),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFEAE5DD);
    final mutedText = isDark ? Colors.white70 : const Color(0xFF6F6F72);

    final now = DateTime.now();
    final String label;
    if (_isSameDay(date, now)) {
      label = 'TODAY';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'YESTERDAY';
    } else {
      label = DateFormat('MMM d, yyyy').format(date).toUpperCase();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: mutedText,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(child: Divider(color: dividerColor, thickness: 0.5)),
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
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _anim,
                builder: (_, child) {
                  final delay = i * 0.2;
                  final val = ((_anim.value - delay).clamp(0.0, 0.6) / 0.6);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6 + val * 4,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE5E5EA);
    final inputBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final shadowColor = isDark ? Colors.transparent : Colors.black.withAlpha(8);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasText = controller.text.trim().isNotEmpty;
        
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              maxLines: 5,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge?.copyWith(color: blackColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white38 : const Color(0xFF9E9E9E),
                  fontSize: 16,
                ),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.only(left: 20, right: 12, top: 14, bottom: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: borderColor, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: borderColor, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: primaryColor, width: 1.0),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 6, top: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasText || isSending 
                          ? primaryColor 
                          : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                      shape: BoxShape.circle,
                    ),
                    child: isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF121212),
                            ),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: hasText && !isSending ? onSend : null,
                            icon: Icon(
                              Icons.send_rounded,
                              color: hasText || isSending 
                                  ? const Color(0xFF121212) 
                                  : (isDark ? Colors.white38 : const Color(0xFF9E9E9E)),
                              size: 20,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}
