import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/models/notification_model.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'providers/notification_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  final bool? showBackButton;

  const NotificationsPage({super.key, this.showBackButton});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
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

  void _selectAll(List<NotificationModel> allNotifications) {
    setState(() {
      if (_selectedIds.length == allNotifications.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(allNotifications.map((n) => n.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;

    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildNormalAppBar(context, blackColor),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: Color(0xFF9E9E9E),
              ),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view your notifications.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF6F6F72),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final groupedAsync = ref.watch(groupedNotificationsProvider);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isSelectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: groupedAsync.when(
          data: (grouped) {
            if (_isSelectionMode) {
              return _buildSelectionAppBar(context, ref, grouped, blackColor);
            }
            return _buildNormalAppBar(context, blackColor);
          },
          loading: () => _buildNormalAppBar(context, blackColor),
          error: (_, __) => _buildNormalAppBar(context, blackColor),
        ),
        body: groupedAsync.when(
          data: (grouped) {
            if (grouped.isEmpty) return _buildEmptyState(context);
            return _buildList(context, ref, grouped);
          },
          loading: () => _buildShimmer(),
          error: (err, stack) {
            String errorMessage =
                "Something went wrong while loading notifications.";
            final errStr = err.toString();
            if (errStr.contains('permission-denied') ||
                errStr.contains('PERMISSION_DENIED')) {
              errorMessage =
                  "Permission denied:\nUnable to load notifications right now.";
            } else if (errStr.contains('network') ||
                errStr.contains('unavailable')) {
              errorMessage = "Unable to load notifications. Please try again.";
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: blackColor, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(
    BuildContext context,
    Color blackColor,
  ) {
    final showBack = widget.showBackButton ??
        (context.canPop() || Navigator.of(context).canPop());

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: blackColor),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            )
          : null,
      title: Text(
        'Notifications',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: blackColor,
        ),
      ),
      centerTitle: true,
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(
    BuildContext context,
    WidgetRef ref,
    GroupedNotifications grouped,
    Color blackColor,
  ) {
    final allNotifications = [
      ...grouped.today,
      ...grouped.yesterday,
      ...grouped.older,
    ];
    final allSelected =
        allNotifications.isNotEmpty &&
        _selectedIds.length == allNotifications.length;

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
          onPressed: () => _selectAll(allNotifications),
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
              _selectAll(allNotifications);
            } else if (val == 'mark_read') {
              ref
                  .read(notificationActionsProvider.notifier)
                  .markMultipleAsRead(_selectedIds.toList());
              _clearSelection();
            } else if (val == 'mark_unread') {
              ref
                  .read(notificationActionsProvider.notifier)
                  .markMultipleAsUnread(_selectedIds.toList());
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
          'Delete notifications?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete $count selected notification${count > 1 ? 's' : ''}?',
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
      ref
          .read(notificationActionsProvider.notifier)
          .deleteMultiple(_selectedIds.toList());
      _clearSelection();
    }
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    GroupedNotifications grouped,
  ) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (grouped.today.isNotEmpty) ...[
          const _SectionHeader(label: 'TODAY'),
          ...grouped.today.map(
            (n) => _NotificationTile(
              notification: n,
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedIds.contains(n.id),
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(n.id);
                } else {
                  _handleNormalTap(n, ref, context);
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  _toggleSelection(n.id);
                }
              },
            ),
          ),
        ],
        if (grouped.yesterday.isNotEmpty) ...[
          const _SectionHeader(label: 'YESTERDAY'),
          ...grouped.yesterday.map(
            (n) => _NotificationTile(
              notification: n,
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedIds.contains(n.id),
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(n.id);
                } else {
                  _handleNormalTap(n, ref, context);
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  _toggleSelection(n.id);
                }
              },
            ),
          ),
        ],
        if (grouped.older.isNotEmpty) ...[
          const _SectionHeader(label: 'EARLIER'),
          ...grouped.older.map(
            (n) => _NotificationTile(
              notification: n,
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedIds.contains(n.id),
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(n.id);
                } else {
                  _handleNormalTap(n, ref, context);
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  _toggleSelection(n.id);
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  void _handleNormalTap(
    NotificationModel notification,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (!notification.isRead) {
      ref
          .read(notificationActionsProvider.notifier)
          .markAsRead(notification.id);
    }
    if (notification.type == 'new_request') {
      context.push('/incoming-requests');
    } else if (notification.type == 'accepted' ||
        notification.type == 'rejected' ||
        notification.type == 'cancelled') {
      context.push('/my-rides');
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blackColor = isDark ? Colors.white : const Color(0xFF121212);
    final grayColor = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 24),
          Text(
            'You\'re all caught up',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: blackColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New ride updates and activity\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: grayColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 8,
      itemBuilder: (context, index) => const _ShimmerTile(),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFA1A1A1),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationTile({
    required this.notification,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.isRead;

    final iconBg = _iconBgForType(notification.type, isDark);
    final iconColor = _iconColorForType(notification.type, isDark);
    final icon = _iconForType(notification.type);

    final unreadBg = isDark ? const Color(0xFF2A2820) : const Color(0xFFFFFDF5);
    final selectedBg = isDark
        ? const Color(0xFF332D19)
        : const Color(0xFFFFFBE6);

    final bgColor = isSelected
        ? selectedBg
        : (isUnread ? unreadBg : Colors.transparent);

    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF3F3F3);

    final titleColor = isDark ? Colors.white : const Color(0xFF121212);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF6F6F72);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: isSelectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFFF4444),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) {
        ref.read(notificationActionsProvider.notifier).delete(notification.id);
      },
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 14, top: 10),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(notification.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFA1A1A1),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: bodyColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnread && !isSelected) ...[
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6C000),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_request':
        return Icons.person_add_alt_1_rounded;
      case 'accepted':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconBgForType(String type, bool isDark) {
    switch (type) {
      case 'new_request':
        return isDark ? const Color(0xFF332D19) : const Color(0xFFFFF8E1);
      case 'accepted':
      case 'completed':
        return isDark ? const Color(0xFF1B3320) : const Color(0xFFE8F5E9);
      case 'rejected':
      case 'cancelled':
        return isDark ? const Color(0xFF331B1B) : const Color(0xFFFFEBEE);
      case 'chat':
        return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3);
      default:
        return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3);
    }
  }

  Color _iconColorForType(String type, bool isDark) {
    switch (type) {
      case 'new_request':
        return const Color(0xFFF6C000);
      case 'accepted':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return isDark ? const Color(0xFFA1A1A1) : const Color(0xFF6F6F72);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d').format(dt);
  }
}

// ─── Shimmer Tile ─────────────────────────────────────────────────────────────

class _ShimmerTile extends StatefulWidget {
  const _ShimmerTile();

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final shimmerColor = Color.lerp(
          isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
          isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
          _anim.value,
        )!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF3F3F3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 160,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
