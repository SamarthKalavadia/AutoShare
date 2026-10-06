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
import 'package:autoshare/shared/providers.dart';
import 'package:autoshare/core/localization/app_localizations.dart';
import 'package:autoshare/features/profile/providers/user_profile_provider.dart';
import 'package:autoshare/data/models/user_model.dart';

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

    final myRides = ref.watch(myRidesProvider).value ?? [];
    final activeRides = myRides.where((r) {
      final s = r.displayStatus;
      return s == 'active' || s == 'joined' || s == 'completed';
    }).toList();

    List<ChatRoom> getResolvedRooms(List<ChatRoom> chatRooms) {
      final currentUid = ref.watch(authControllerProvider).value?.uid ??
          FirebaseAuth.instance.currentUser?.uid ??
          '';
      if (currentUid.isEmpty) return [];

      // Helper to identify the conversation partner UID for a room
      String getOtherUid(ChatRoom room) {
        // 1. Check messages for this room
        final msgs = ref.read(chatMessagesProvider(room.rideId)).value ?? [];
        if (msgs.isNotEmpty) {
          final latest = msgs.reduce((a, b) => a.sentAt.isAfter(b.sentAt) ? a : b);
          if (latest.senderId.isNotEmpty && latest.senderId != currentUid) {
            return latest.senderId;
          }
          if (latest.receiverUid.isNotEmpty && latest.receiverUid != currentUid) {
            return latest.receiverUid;
          }
          for (final m in msgs.reversed) {
            if (m.senderId.isNotEmpty && m.senderId != currentUid) {
              return m.senderId;
            }
            if (m.receiverUid.isNotEmpty && m.receiverUid != currentUid) {
              return m.receiverUid;
            }
          }
        }

        // 2. Check active ride
        final matchingRide = activeRides.where((r) => r.ride.id == room.rideId).firstOrNull;
        if (matchingRide != null) {
          final ridePartner = matchingRide.role == 'driver'
              ? (matchingRide.request?.requesterUid ?? '')
              : matchingRide.ride.driverId;
          if (ridePartner.isNotEmpty && ridePartner != currentUid) {
            return ridePartner;
          }
        }

        // 3. Fallback to room participants
        return room.participants.firstWhere(
          (p) => p.isNotEmpty && p != currentUid,
          orElse: () => '',
        );
      }

      // Map to deduplicate chats by the other user (partner) UID
      final Map<String, ChatRoom> byUserMap = {};

      for (final room in chatRooms) {
        final otherUid = getOtherUid(room);
        // Exclude rooms with no valid other user ("Ride Partner" / self)
        if (otherUid.isEmpty || otherUid == currentUid) continue;

        if (!byUserMap.containsKey(otherUid)) {
          byUserMap[otherUid] = room;
        } else {
          final existing = byUserMap[otherUid]!;
          final hasMsg = room.lastMessageText.trim().isNotEmpty;
          final existingHasMsg = existing.lastMessageText.trim().isNotEmpty;

          // If this room has messages and existing doesn't, prefer this room
          if (hasMsg && !existingHasMsg) {
            byUserMap[otherUid] = room;
          } else if (!hasMsg && existingHasMsg) {
            // Keep existing
          } else {
            // Otherwise keep the one with the latest timestamp
            final existingTime = existing.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final roomTime = room.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            if (roomTime.isAfter(existingTime)) {
              byUserMap[otherUid] = room;
            }
          }
        }
      }

      // Add active rides only if there's an actual other participant not yet present in byUserMap
      for (final r in activeRides) {
        final otherUid = r.role == 'driver'
            ? (r.request?.requesterUid ?? '')
            : r.ride.driverId;
        // Strictly ignore if no other user or if other user is self
        if (otherUid.isEmpty || otherUid == currentUid) continue;

        if (!byUserMap.containsKey(otherUid)) {
          byUserMap[otherUid] = ChatRoom(
            chatId: r.ride.id,
            rideId: r.ride.id,
            participants: [currentUid, otherUid],
            lastMessageText: '',
            lastMessageAt: r.ride.departureTime,
          );
        }
      }

      final list = byUserMap.values.toList();
      list.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    }

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
            final validRooms = getResolvedRooms(chatRooms);
            final allIds = validRooms.map((r) => r.chatId).toList();
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
            final validRooms = getResolvedRooms(chatRooms);

            if (validRooms.isEmpty) {
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
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16).copyWith(bottom: 24),
              itemCount: validRooms.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final room = validRooms[index];
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
          loading: () => Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
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
    final msgs = ref.read(chatMessagesProvider(room.rideId)).value ?? [];
    var otherUid = participantUid ?? '';

    if (otherUid.isEmpty && msgs.isNotEmpty) {
      final latest = msgs.reduce((a, b) => a.sentAt.isAfter(b.sentAt) ? a : b);
      if (latest.senderId.isNotEmpty && latest.senderId != currentUid) {
        otherUid = latest.senderId;
      } else if (latest.receiverUid.isNotEmpty && latest.receiverUid != currentUid) {
        otherUid = latest.receiverUid;
      }
      if (otherUid.isEmpty) {
        for (final m in msgs.reversed) {
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
    }

    // Check if we have the full ride model in myRidesProvider
    final myRides = ref.read(myRidesProvider).value ?? [];
    final matchingRide = myRides.where((r) => r.ride.id == room.rideId).firstOrNull;

    if (otherUid.isEmpty && matchingRide != null) {
      otherUid = matchingRide.role == 'driver'
          ? (matchingRide.request?.requesterUid ?? '')
          : matchingRide.ride.driverId;
    }

    if (otherUid.isEmpty) {
      otherUid = room.participants.firstWhere(
        (p) => p.isNotEmpty && p != currentUid,
        orElse: () => '',
      );
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
    final myRides = ref.watch(myRidesProvider).value ?? [];
    final match = myRides.where((r) => r.ride.id == chatRoom.rideId).firstOrNull;

    final messagesAsync = ref.watch(chatMessagesProvider(rideId));
    final messagesList = messagesAsync.value ?? [];

    // Step 1: Check messages first to see who was actually in conversation
    var otherUid = '';
    if (messagesList.isNotEmpty) {
      final latestMsg = messagesList.reduce((a, b) => a.sentAt.isAfter(b.sentAt) ? a : b);
      if (latestMsg.senderId.isNotEmpty && latestMsg.senderId != currentUid) {
        otherUid = latestMsg.senderId;
      } else if (latestMsg.receiverUid.isNotEmpty && latestMsg.receiverUid != currentUid) {
        otherUid = latestMsg.receiverUid;
      }
      if (otherUid.isEmpty) {
        for (final m in messagesList.reversed) {
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
    }

    // Step 2: Check matching ride
    if (otherUid.isEmpty && match != null) {
      otherUid = match.role == 'driver'
          ? (match.request?.requesterUid ?? '')
          : match.ride.driverId;
    }

    // Step 3: Check participants
    final candidateUids = chatRoom.participants
        .where((p) => p.isNotEmpty && p != currentUid)
        .toList();

    if (otherUid.isEmpty && candidateUids.isNotEmpty) {
      otherUid = candidateUids.first;
    }

    final otherUserAsync = ref.watch(chatUserProvider(otherUid));
    final otherUserProfileAsync = otherUid.isNotEmpty
        ? ref.watch(userProfileProvider(otherUid))
        : null;

    UserModel? resolvedUser = otherUserAsync.value ?? otherUserProfileAsync?.value;

    // Step 4: If resolvedUser is null or has empty profile image and name, but other candidate UIDs exist, check them
    if ((resolvedUser == null || (resolvedUser.name.isEmpty && resolvedUser.profileImage.isEmpty)) && candidateUids.length > 1) {
      for (final cid in candidateUids) {
        if (cid == otherUid) continue;
        final candidateUser = ref.watch(chatUserProvider(cid)).value;
        if (candidateUser != null && (candidateUser.name.isNotEmpty || candidateUser.profileImage.isNotEmpty)) {
          resolvedUser = candidateUser;
          otherUid = cid;
          break;
        }
      }
    }

    final participantName = () {
      if (resolvedUser != null &&
          resolvedUser.name.trim().isNotEmpty &&
          resolvedUser.name.trim().toLowerCase() != 'user' &&
          resolvedUser.name.trim().toLowerCase() != 'driver') {
        return resolvedUser.name.trim();
      }
      if (resolvedUser != null && resolvedUser.email.trim().isNotEmpty) {
        final emailPart = resolvedUser.email.trim().split('@').first;
        if (emailPart.isNotEmpty &&
            emailPart.toLowerCase() != 'user' &&
            emailPart.toLowerCase() != 'driver') {
          return emailPart[0].toUpperCase() + emailPart.substring(1);
        }
      }
      if (match != null &&
          match.role == 'passenger' &&
          match.ride.driverName.trim().isNotEmpty &&
          match.ride.driverName.trim() != 'Unknown Driver' &&
          match.ride.driverName.trim().toLowerCase() != 'driver' &&
          match.ride.driverName.trim().toLowerCase() != 'user') {
        return match.ride.driverName.trim();
      }
      for (final m in messagesList.reversed) {
        if (m.senderId.isNotEmpty &&
            m.senderId != currentUid &&
            m.senderName.trim().isNotEmpty &&
            m.senderName.trim().toLowerCase() != 'user' &&
            m.senderName.trim().toLowerCase() != 'driver') {
          return m.senderName.trim();
        }
      }
      if (resolvedUser != null &&
          resolvedUser.name.trim().isNotEmpty &&
          resolvedUser.name.trim().toLowerCase() != 'driver') {
        return resolvedUser.name.trim();
      }
      return otherUserAsync.isLoading ? 'Loading...' : 'Ride Partner';
    }();

    final participantAvatar = (resolvedUser?.profileImage != null &&
            resolvedUser!.profileImage.trim().isNotEmpty)
        ? resolvedUser.profileImage.trim()
        : null;

    final unreadCount = messagesList
            .where((m) => m.senderId != currentUid && !m.isReadBy(currentUid))
            .length;
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

    final isDeletedAccount = otherUserAsync.hasValue && otherUserAsync.value == null && otherUid.isNotEmpty;
    if (isDeletedAccount && realLastMessageText.trim().isEmpty && messagesList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Never show an empty chat partner, self-chat, or "Ride Partner"
    if (otherUid.isEmpty || otherUid == currentUid || participantName == 'Ride Partner') {
      return const SizedBox.shrink();
    }

    final cardWidget = Material(
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
                              : (match != null && match.ride.boardingLocation.isNotEmpty
                                  ? '${match.ride.boardingLocation} → ${match.ride.destination}'
                                  : context.l10n.startConversation)),
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

    if (isSelectionMode) {
      return cardWidget;
    }

    return Dismissible(
      key: ValueKey('chat_${chatRoom.chatId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(context.l10n.delete, style: TextStyle(color: textColor)),
            content: Text(
              "Are you sure you want to delete this chat?",
              style: TextStyle(color: subtextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                child: Text(context.l10n.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(chatRepositoryProvider).deleteChatRooms([chatRoom.chatId]);
      },
      child: cardWidget,
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
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageProvider != null
          ? Image(
              image: imageProvider,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    initial,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                );
              },
            )
          : Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
    );
  }
}
