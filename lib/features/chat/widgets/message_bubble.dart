import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:autoshare/data/models/chat_model.dart';
import 'package:autoshare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoshare/features/chat/providers/chat_provider.dart';

class MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool showSenderName;
  final bool isGrouped;

  const MessageBubble({
    super.key,
    required this.message,
    this.showSenderName = false,
    this.isGrouped = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFFF6C000);
    const blackColor = Color(0xFF121212);
    const mutedText = Color(0xFF6F6F72);

    final currentUid = ref.watch(authControllerProvider).value?.uid ?? '';
    final isMe = message.senderId == currentUid;
    final rideId = message.rideId;

    if (message.isDeleted) {
      return Padding(
        padding: EdgeInsets.only(
          top: isGrouped ? 2 : 12,
          bottom: 2,
          left: isMe ? 60 : 16,
          right: isMe ? 16 : 60,
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text('🚫 Message deleted',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: mutedText,
                    fontStyle: FontStyle.italic)),
          ),
        ),
      );
    }

    final isRead = message.readBy.length > 1;

    return GestureDetector(
      onLongPress: () => _showOptions(context, ref, isMe, rideId),
      child: Padding(
        padding: EdgeInsets.only(
          top: isGrouped ? 2 : 12,
          bottom: 2,
          left: isMe ? 60 : 16,
          right: isMe ? 16 : 60,
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? primaryColor : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe
                    ? const Radius.circular(20)
                    : const Radius.circular(4),
                bottomRight: isMe
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                    color: blackColor.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe && showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(message.senderName,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryColor)),
                  ),
                Text(message.text,
                    style: GoogleFonts.inter(
                        fontSize: 15, color: blackColor)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.sentAt),
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isMe
                              ? blackColor.withAlpha(100)
                              : mutedText),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead
                            ? Colors.blue.shade600
                            : blackColor.withAlpha(100),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(
      BuildContext context, WidgetRef ref, bool isMe, String rideId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFEAE5DD),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text('Copy message',
                  style: GoogleFonts.inter(fontSize: 15)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')));
              },
            ),
            if (isMe)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text('Delete message',
                    style: GoogleFonts.inter(
                        fontSize: 15, color: Colors.red)),
                onTap: () {
                  ref
                      .read(chatProvider.notifier)
                      .deleteMessage(message.messageId);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
