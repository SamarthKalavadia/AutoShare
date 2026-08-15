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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final bubbleBgMy = primaryColor;
    final bubbleBgOther = theme.cardTheme.color ?? (isDark ? const Color(0xFF2C2C2E) : Colors.white);
    final deletedBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE);

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
              color: deletedBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text('🚫 Message deleted',
                style: theme.textTheme.bodySmall?.copyWith(
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
              color: isMe ? bubbleBgMy : bubbleBgOther,
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
              boxShadow: isDark ? [] : [
                BoxShadow(
                    color: const Color(0xFF121212).withAlpha(8),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primaryColor)),
                  ),
                Text(message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: isMe ? const Color(0xFF121212) : blackColor)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.sentAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: isMe
                              ? const Color(0xFF121212).withAlpha(150)
                              : mutedText),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead
                            ? Colors.blue.shade700
                            : const Color(0xFF121212).withAlpha(150),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final handleColor = isDark ? Colors.white24 : const Color(0xFFEAE5DD);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
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
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: theme.colorScheme.onSurface),
              title: Text('Copy message',
                  style: theme.textTheme.bodyLarge),
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
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red)),
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
