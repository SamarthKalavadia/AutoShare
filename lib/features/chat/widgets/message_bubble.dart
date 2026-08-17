import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    
    final currentUid = ref.watch(authControllerProvider).value?.uid ?? '';
    final isMe = message.senderId == currentUid;
    final rideId = message.rideId;

    final bubbleBgMy = primaryColor;
    final bubbleBgOther = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final deletedBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE);

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 14, color: mutedText),
                const SizedBox(width: 6),
                Text(
                  'Message deleted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isRead = message.readBy.keys.any((uid) => uid != message.senderId && message.readBy[uid] == true);

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
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? bubbleBgMy : bubbleBgOther,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe || isGrouped ? 20 : 4),
                bottomRight: Radius.circular(!isMe || isGrouped ? 20 : 4),
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(isMe ? 12 : 6),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe && showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message.senderName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? primaryColor : const Color(0xFFDB9900),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe ? const Color(0xFF121212) : blackColor,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.sentAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: isMe ? const Color(0xFF121212).withAlpha(140) : mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all_rounded : Icons.check_rounded,
                        size: 14,
                        color: isRead
                            ? Colors.blue.shade700
                            : const Color(0xFF121212).withAlpha(140),
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
    BuildContext context,
    WidgetRef ref,
    bool isMe,
    String rideId,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final handleColor = isDark ? Colors.white24 : const Color(0xFFEAE5DD);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: theme.colorScheme.onSurface),
              title: Text('Copy text', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text(
                  'Delete message',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  ref.read(chatProvider.notifier).deleteMessage(message.messageId);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
