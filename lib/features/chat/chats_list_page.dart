import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:autoshare/data/models/chat_model.dart';
import 'package:autoshare/data/models/ride_model.dart';
import 'package:autoshare/features/my_rides/providers/my_rides_provider.dart';
import 'package:autoshare/features/chat/providers/chat_provider.dart';
import 'package:autoshare/features/auth/presentation/controllers/auth_controller.dart';

class ChatsListPage extends ConsumerStatefulWidget {
  const ChatsListPage({super.key});

  @override
  ConsumerState<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends ConsumerState<ChatsListPage> {
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _selectAll(List<String> allIds) {
    setState(() {
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(allIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userChatsAsync = ref.watch(userChatsStreamProvider);
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: userChatsAsync.when(
          data: (chatRooms) {
            final allIds = chatRooms.map((r) => r.chatId).toList();
            if (_isSelectionMode) {
              return _buildSelectionAppBar(context, ref, allIds, textColor);
            }
            return _buildNormalAppBar(context, textColor);
          },
          loading: () => _buildNormalAppBar(context, textColor),
          error: (_, __) => _buildNormalAppBar(context, textColor),
        ),
        body: userChatsAsync.when(
          data: (chatRooms) {
            if (chatRooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active chats yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conversations with drivers and riders will appear here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: chatRooms.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF3F3F3),
              ),
              itemBuilder: (context, index) {
                final room = chatRooms[index];
                final chatId = room.chatId;
                return _ChatCard(
                  chatRoom: room,
                  isSelectionMode: _isSelectionMode,
                  isSelected: _selectedIds.contains(chatId),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(chatId);
                    } else {
                      _handleNormalTap(room);
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _toggleSelection(chatId);
                    }
                  },
                );
              },
            );
          },
          loading: () {
            final rides = ref.watch(myRidesProvider).value ?? [];
            final activeRides = rides.where((r) {
              final status = r.displayStatus;
              return status == 'active' || status == 'joined' || status == 'completed';
            }).toList();

            if (activeRides.isEmpty) {
              return Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: activeRides.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF3F3F3),
              ),
              itemBuilder: (context, index) {
                final r = activeRides[index];
                final otherUid = r.role == 'driver'
                    ? (r.request?.requesterUid ?? '')
                    : r.ride.driverId;
                return _ChatCard(
                  chatRoom: ChatRoom(
                    chatId: r.ride.id,
                    rideId: r.ride.id,
                    participants: [otherUid],
                    lastMessageText: '${r.ride.boardingLocation} → ${r.ride.destination}',
                    lastMessageAt: r.ride.departureTime,
                  ),
                  isSelectionMode: false,
                  isSelected: false,
                  onTap: () {
                    context.push(
                      '/chat',
                      extra: ChatPageArgs(
                        ride: r.ride,
                        otherParticipantUid: otherUid,
                        otherParticipantName: '',
                      ),
                    );
                  },
                  onLongPress: () {},
                );
              },
            );
          },
          error: (err, _) => Center(
            child: Text(
              'Error loading chats: $err',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  void _handleNormalTap(ChatRoom room) {
    final currentUid = ref.read(authControllerProvider).value?.uid ?? '';
    final otherUid = room.participants.firstWhere(
      (p) => p != currentUid,
      orElse: () => '',
    );

    // Check if we have the full ride model in myRidesProvider
    final myRides = ref.read(myRidesProvider).value ?? [];
    final matchingRide = myRides.where((r) => r.ride.id == room.rideId).firstOrNull;

    final ride = matchingRide?.ride ??
        RideModel(
          id: room.rideId,
          driverId: otherUid,
          boardingLocation: 'Shared Route',
          destination: 'Destination',
          farePerSeat: 0,
          availableSeats: 0,
          departureTime: room.lastMessageAt ?? DateTime.now(),
          createdAt: DateTime.now(),
        );

    context.push(
      '/chat',
      extra: ChatPageArgs(
        ride: ride,
        otherParticipantUid: otherUid,
        otherParticipantName: '',
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(
    BuildContext context,
    Color textColor,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      title: Text(
        'Chats',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(
    BuildContext context,
    WidgetRef ref,
    List<String> allIds,
    Color blackColor,
  ) {
    final allSelected = allIds.isNotEmpty && _selectedIds.length == allIds.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final iconColor = isDark ? Colors.white70 : const Color(0xFF6F6F72);
    final textStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: blackColor,
    );

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: blackColor),
        onPressed: _clearSelection,
      ),
      title: Text(
        '${_selectedIds.length} selected',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: blackColor,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all, color: blackColor),
          tooltip: allSelected ? 'Deselect all' : 'Select all',
          onPressed: () => _selectAll(allIds),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: blackColor),
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: blackColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          color: menuColor,
          offset: const Offset(0, 48),
          onSelected: (val) {
            if (val == 'select_all') {
              _selectAll(allIds);
            } else if (val == 'mark_read') {
              ref.read(chatsListActionsProvider.notifier).markMultipleAsRead(_selectedIds.toList());
              _clearSelection();
            } else if (val == 'mark_unread') {
              ref.read(chatsListActionsProvider.notifier).markMultipleAsUnread(_selectedIds.toList());
              _clearSelection();
            } else if (val == 'delete') {
              _confirmDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'select_all',
              height: 48,
              child: Row(
                children: [
                  Icon(
                    allSelected ? Icons.deselect : Icons.select_all,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    allSelected ? 'Deselect all' : 'Select all',
                    style: textStyle,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'mark_read',
              height: 48,
              child: Row(
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text('Mark as read', style: textStyle),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'mark_unread',
              height: 48,
              child: Row(
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text('Mark as unread', style: textStyle),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              height: 48,
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFD32F2F),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete',
                    style: textStyle.copyWith(color: const Color(0xFFD32F2F)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final count = _selectedIds.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete conversations?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete $count selected conversation${count > 1 ? 's' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF6F6F72),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(chatsListActionsProvider.notifier).deleteMultiple(_selectedIds.toList());
        _clearSelection();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't delete conversation. Please try again.")),
          );
        }
      }
    }
  }
}

class _ChatCard extends ConsumerWidget {
  final ChatRoom chatRoom;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatCard({
    required this.chatRoom,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentUid = ref.watch(authControllerProvider).value?.uid ?? '';
    final rideId = chatRoom.rideId;

    final otherUid = chatRoom.participants.firstWhere(
      (p) => p != currentUid,
      orElse: () => '',
    );

    final otherUserAsync = ref.watch(chatUserProvider(otherUid));

    final participantName = otherUserAsync.when(
      data: (user) {
        if (user != null && user.name.isNotEmpty) return user.name;
        return 'User';
      },
      loading: () => 'Loading...',
      error: (_, __) => 'User',
    );
    final participantAvatar = otherUserAsync.value?.profileImage;

    final messagesAsync = ref.watch(chatMessagesProvider(rideId));
    final unreadCount = messagesAsync.value
            ?.where((m) => m.senderId != currentUid && !m.isReadBy(currentUid))
            .length ??
        0;

    final lastMessageText = chatRoom.lastMessageText;
    final lastMessageAt = chatRoom.lastMessageAt;

    final isTyping = chatRoom.typing.entries.any((e) => e.key == otherUid && e.value);

    final selectedBg = isDark ? const Color(0xFF332D19) : const Color(0xFFFFFBE6);
    final cardBg = isSelected ? selectedBg : Colors.transparent;

    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final subtextColor = isDark ? Colors.white60 : Colors.grey[600];

    return Material(
      color: cardBg,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? const Color(0xFFFFC400)
                        : (isDark ? Colors.white30 : Colors.black26),
                    size: 20,
                  ),
                ),
              CircleAvatar(
                radius: 26,
                backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEAE5DD),
                backgroundImage: participantAvatar != null && participantAvatar.isNotEmpty
                    ? NetworkImage(participantAvatar)
                    : null,
                child: participantAvatar == null || participantAvatar.isEmpty
                    ? Text(
                        participantName.isNotEmpty ? participantName[0].toUpperCase() : '?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            participantName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                              color: textColor,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageAt != null)
                          Text(
                            _formatTime(lastMessageAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: unreadCount > 0 ? primaryColor : subtextColor,
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isTyping
                                ? 'typing...'
                                : (lastMessageText.isNotEmpty
                                    ? lastMessageText
                                    : 'Tap to chat'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isTyping
                                  ? primaryColor
                                  : (unreadCount > 0 ? textColor : subtextColor),
                              fontWeight: (isTyping || unreadCount > 0)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0 && !isSelected)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Color(0xFF121212),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    } else if (time.year == now.year && time.month == now.month && time.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
