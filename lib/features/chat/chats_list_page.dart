import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:autoshare/data/models/chat_model.dart';
import 'package:autoshare/data/models/ride_model.dart';
import 'package:autoshare/features/my_rides/providers/my_rides_provider.dart';
import 'package:autoshare/features/chat/providers/chat_provider.dart';
import 'package:autoshare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoshare/shared/utils/avatar_utils.dart';
import 'package:autoshare/core/localization/app_localizations.dart';

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
          error: (error, _) => _buildNormalAppBar(context, textColor),
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
                      context.l10n.noMessagesYet,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.noChatsSubtitle,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16).copyWith(bottom: 24),
              itemCount: chatRooms.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                  onTapWithDetails: (pName, pUid) {
                    if (_isSelectionMode) {
                      _toggleSelection(chatId);
                    } else {
                      _handleNormalTap(room, participantName: pName, participantUid: pUid);
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16).copyWith(bottom: 24),
              itemCount: activeRides.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = activeRides[index];
                final otherUid = r.role == 'driver'
                    ? (r.request?.requesterUid ?? '')
                    : r.ride.driverId;
                final driverName = (r.role == 'passenger' &&
                        r.ride.driverName.isNotEmpty &&
                        r.ride.driverName != 'Unknown Driver' &&
                        r.ride.driverName.toLowerCase() != 'driver')
                    ? r.ride.driverName
                    : '';
                return _ChatCard(
                  chatRoom: ChatRoom(
                    chatId: r.ride.id,
                    rideId: r.ride.id,
                    participants: [otherUid],
                    lastMessageText: '',
                    lastMessageAt: r.ride.departureTime,
                  ),
                  isSelectionMode: false,
                  isSelected: false,
                  onTapWithDetails: (pName, pUid) {
                    final cleanPName = (pName.isNotEmpty &&
                            pName.toLowerCase() != 'user' &&
                            pName.toLowerCase() != 'driver')
                        ? pName
                        : '';
                    context.push(
                      '/chat',
                      extra: ChatPageArgs(
                        ride: r.ride,
                        otherParticipantUid: otherUid.isNotEmpty ? otherUid : pUid,
                        otherParticipantName: cleanPName.isNotEmpty
                            ? cleanPName
                            : (driverName.isNotEmpty ? driverName : ''),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark ? Colors.white70 : const Color(0xFF121212),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNormalTap(ChatRoom room, {String? participantName, String? participantUid}) {
    final currentUid = ref.read(authControllerProvider).value?.uid ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    var otherUid = participantUid ??
        room.participants.firstWhere(
          (p) => p.isNotEmpty && p != currentUid,
          orElse: () => '',
        );

    // Check if we have the full ride model in myRidesProvider
    final myRides = ref.read(myRidesProvider).value ?? [];
    final matchingRide = myRides.where((r) => r.ride.id == room.rideId).firstOrNull;

    if (otherUid.isEmpty && matchingRide != null) {
      otherUid = matchingRide.role == 'driver'
          ? (matchingRide.request?.requesterUid ?? '')
          : matchingRide.ride.driverId;
    }

    if (otherUid.isEmpty) {
      final msgs = ref.read(chatMessagesProvider(room.rideId)).value ?? [];
      for (final m in msgs) {
        if (m.senderId.isNotEmpty && m.senderId != currentUid) {
          otherUid = m.senderId;
          break;
        }
        if (m.receiverUid.isNotEmpty && m.receiverUid != currentUid) {
          otherUid = m.receiverUid;
          break;
        }
      }
    }

    String resolvedName = participantName ?? '';
    if (resolvedName.isEmpty ||
        resolvedName.toLowerCase() == 'user' ||
        resolvedName.toLowerCase() == 'driver' ||
        resolvedName == 'Ride Partner') {
      if (matchingRide != null &&
          matchingRide.role == 'passenger' &&
          matchingRide.ride.driverName.isNotEmpty &&
          matchingRide.ride.driverName != 'Unknown Driver' &&
          matchingRide.ride.driverName.toLowerCase() != 'driver') {
        resolvedName = matchingRide.ride.driverName;
      }
    }

    final ride = matchingRide?.ride ??
        RideModel(
          id: room.rideId,
          driverId: otherUid.isNotEmpty ? otherUid : currentUid,
          driverName: resolvedName.isNotEmpty ? resolvedName : 'Ride Partner',
          boardingLocation: 'Shared Route',
          destination: 'Destination',
          totalFare: 0,
          availableSeats: 0,
          departureTime: room.lastMessageAt ?? DateTime.now(),
          createdAt: DateTime.now(),
        );

    context.push(
      '/chat',
      extra: ChatPageArgs(
        ride: ride,
        otherParticipantUid: otherUid,
        otherParticipantName: resolvedName.isNotEmpty && resolvedName != 'User' ? resolvedName : '',
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
      toolbarHeight: 70,
      title: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 8.0),
        child: Text(
          context.l10n.navChats,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      centerTitle: false,
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
        '${_selectedIds.length} ${context.l10n.selectedCountText}',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: blackColor,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all, color: blackColor),
          tooltip: allSelected ? context.l10n.deselectAll : context.l10n.selectAll,
          onPressed: () => _selectAll(allIds),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: blackColor),
          tooltip: context.l10n.delete,
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
                    allSelected ? context.l10n.deselectAll : context.l10n.selectAll,
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
                  Text(context.l10n.markAsRead, style: textStyle),
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
                  Text(context.l10n.markAsUnread, style: textStyle),
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
                    context.l10n.delete,
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
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF121212),
          ),
        ),
        content: Text(
          'Delete $count ${context.l10n.selectedCountText} conversation${count > 1 ? 's' : ''}?',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white70 : const Color(0xFF6F6F72),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.l10n.cancel,
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
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(chatsListActionsProvider.notifier).deleteMultiple(_selectedIds.toList());
        _clearSelection();
      } catch (e) {
        if (mounted) {
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
  final VoidCallback? onTap;
  final void Function(String participantName, String participantUid)? onTapWithDetails;
  final VoidCallback onLongPress;

  const _ChatCard({
    required this.chatRoom,
    required this.isSelectionMode,
    required this.isSelected,
    this.onTap,
    this.onTapWithDetails,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentUid = ref.watch(authControllerProvider).value?.uid ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    final rideId = chatRoom.rideId;

    var otherUid = chatRoom.participants.firstWhere(
      (p) => p.isNotEmpty && p != currentUid,
      orElse: () => '',
    );

    if (otherUid.isEmpty) {
      final myRides = ref.watch(myRidesProvider).value ?? [];
      final match = myRides.where((r) => r.ride.id == chatRoom.rideId).firstOrNull;
      if (match != null) {
        otherUid = match.role == 'driver'
            ? (match.request?.requesterUid ?? '')
            : match.ride.driverId;
      }
    }

    if (otherUid.isEmpty) {
      final msgs = ref.watch(chatMessagesProvider(rideId)).value ?? [];
      for (final m in msgs) {
        if (m.senderId.isNotEmpty && m.senderId != currentUid) {
          otherUid = m.senderId;
          break;
        }
        if (m.receiverUid.isNotEmpty && m.receiverUid != currentUid) {
          otherUid = m.receiverUid;
          break;
        }
      }
    }

    final otherUserAsync = ref.watch(chatUserProvider(otherUid));
    final messagesAsync = ref.watch(chatMessagesProvider(rideId));

    final participantName = () {
      final user = otherUserAsync.value;
      if (user != null &&
          user.name.trim().isNotEmpty &&
          user.name.trim().toLowerCase() != 'user' &&
          user.name.trim().toLowerCase() != 'driver') {
        return user.name.trim();
      }
      if (user != null && user.email.trim().isNotEmpty) {
        final emailPart = user.email.trim().split('@').first;
        if (emailPart.isNotEmpty &&
            emailPart.toLowerCase() != 'user' &&
            emailPart.toLowerCase() != 'driver') {
          return emailPart[0].toUpperCase() + emailPart.substring(1);
        }
      }
      final myRides = ref.watch(myRidesProvider).value ?? [];
      final match = myRides.where((r) => r.ride.id == chatRoom.rideId).firstOrNull;
      if (match != null &&
          match.role == 'passenger' &&
          match.ride.driverName.trim().isNotEmpty &&
          match.ride.driverName.trim() != 'Unknown Driver' &&
          match.ride.driverName.trim().toLowerCase() != 'driver' &&
          match.ride.driverName.trim().toLowerCase() != 'user') {
        return match.ride.driverName.trim();
      }
      final msgs = messagesAsync.value ?? [];
      for (final m in msgs) {
        if (m.senderId.isNotEmpty &&
            m.senderId != currentUid &&
            m.senderName.trim().isNotEmpty &&
            m.senderName.trim().toLowerCase() != 'user' &&
            m.senderName.trim().toLowerCase() != 'driver') {
          return m.senderName.trim();
        }
      }
      if (user != null &&
          user.name.trim().isNotEmpty &&
          user.name.trim().toLowerCase() != 'driver') {
        return user.name.trim();
      }
      return otherUserAsync.isLoading ? 'Loading...' : 'Ride Partner';
    }();
    final participantAvatar = otherUserAsync.value?.profileImage;

    final unreadCount = messagesAsync.value
            ?.where((m) => m.senderId != currentUid && !m.isReadBy(currentUid))
            .length ??
        0;

    final messagesList = messagesAsync.value ?? [];
    String realLastMessageText = chatRoom.lastMessageText;
    
    if (messagesList.isNotEmpty) {
      final latestMsg = messagesList.reduce((a, b) => a.sentAt.isAfter(b.sentAt) ? a : b);
      realLastMessageText = latestMsg.text;
    }

    final lastMessageAt = chatRoom.lastMessageAt;

    final isTyping = chatRoom.typing.entries.any((e) => e.key == otherUid && e.value);

    final selectedBg = isDark ? const Color(0xFF332D19) : const Color(0xFFFFFBE6);
    final cardBg = isSelected 
        ? selectedBg 
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final primaryColor = theme.colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF6F6F72);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTapWithDetails != null) {
            onTapWithDetails!(participantName, otherUid);
          } else {
            onTap?.call();
          }
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelectionMode && isSelected 
                  ? primaryColor 
                  : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFEF)),
              width: isSelectionMode && isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              _UserAvatar(
                imageUrl: participantAvatar,
                name: participantName,
                radius: 27,
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
                        if (unreadCount > 0 && !isSelected)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                unreadCount.toString(),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        else if (lastMessageAt != null && !isSelected)
                          Text(
                            _formatTime(context, lastMessageAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtextColor,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTyping
                          ? context.l10n.typing
                          : (realLastMessageText.isNotEmpty
                              ? realLastMessageText
                              : context.l10n.startConversation),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    } else if (time.year == now.year && time.month == now.month && time.day == now.day - 1) {
      return context.l10n.yesterday;
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}

class _UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const _UserAvatar({
    required this.imageUrl,
    required this.name,
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEAE5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    final imageProvider = getAvatarImageProvider(imageUrl);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        image: imageProvider != null
            ? DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: imageProvider == null
          ? Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            )
          : null,
    );
  }
}
