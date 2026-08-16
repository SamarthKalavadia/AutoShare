import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/models/notification_model.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'providers/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;

    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(
          context,
          ref,
          false,
          primaryColor,
          blackColor,
          false,
        ),
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
    final isMarkingAll = ref.watch(notificationActionsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(
        context,
        ref,
        isMarkingAll,
        primaryColor,
        blackColor,
        true,
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
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    bool isMarkingAll,
    Color primaryColor,
    Color blackColor,
    bool showActions,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = showActions
        ? ref.watch(unreadNotificationCountProvider) > 0
        : false;

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFEAE5DD),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x33000000)
                    : const Color(0x0A121212),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: isDark ? Colors.white : const Color(0xFF121212),
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Notifications',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: blackColor,
        ),
      ),
      centerTitle: true,
      actions: showActions
          ? [
              TextButton(
                onPressed: (isMarkingAll || !hasUnread)
                    ? null
                    : () => ref
                          .read(notificationActionsProvider.notifier)
                          .markAllAsRead(),
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: (isMarkingAll || !hasUnread)
                        ? const Color(0xFFAAAAAA)
                        : primaryColor,
                  ),
                ),
              ),
            ]
          : [],
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    GroupedNotifications grouped,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (grouped.today.isNotEmpty) ...[
          _SectionHeader(label: 'Today'),
          ...grouped.today.map((n) => _NotificationTile(notification: n)),
        ],
        if (grouped.yesterday.isNotEmpty) ...[
          _SectionHeader(label: 'Yesterday'),
          ...grouped.yesterday.map((n) => _NotificationTile(notification: n)),
        ],
        if (grouped.older.isNotEmpty) ...[
          _SectionHeader(label: 'Older'),
          ...grouped.older.map((n) => _NotificationTile(notification: n)),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blackColor = isDark ? Colors.white : const Color(0xFF121212);
    final iconBgColor = isDark
        ? const Color(0xFF332D19)
        : const Color(0xFFF8F3E7);
    final iconColor = isDark
        ? const Color(0xFFF6C000)
        : const Color(0xFF121212);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: blackColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF6F6F72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ShimmerTile(),
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
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6F6F72),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.isRead;

    final iconBg = _iconBgForType(notification.type);
    final iconColor = _iconColorForType(notification.type);
    final icon = _iconForType(notification.type);

    final cardBg = isUnread
        ? (isDark ? const Color(0xFF332D19) : const Color(0xFFFFF8E1))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final cardBorder = isUnread
        ? (isDark ? const Color(0xFF5C4E14) : const Color(0xFFFFE082))
        : (isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD));

    final titleColor = isDark ? Colors.white : const Color(0xFF121212);
    final bodyColor = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) {
        ref.read(notificationActionsProvider.notifier).delete(notification.id);
      },
      child: InkWell(
        onTap: () {
          if (isUnread) {
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
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: isUnread
                    ? const Color(0x12F6C000)
                    : (isDark
                          ? const Color(0x33000000)
                          : const Color(0x08121212)),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
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
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF6C000),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
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
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFAAAAAA),
                        fontWeight: FontWeight.w500,
                      ),
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_request':
        return Icons.person_add_outlined;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.block_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'reminder':
        return Icons.access_time_rounded;
      case 'starting_soon':
        return Icons.directions_car_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBgForType(String type) {
    switch (type) {
      case 'new_request':
        return const Color(0xFFE3F2FD);
      case 'accepted':
        return const Color(0xFFE8F5E9);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      case 'cancelled':
        return const Color(0xFFFFF3E0);
      case 'chat':
        return const Color(0xFFF3E5F5);
      case 'reminder':
      case 'starting_soon':
        return const Color(0xFFFFF8E1);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _iconColorForType(String type) {
    switch (type) {
      case 'new_request':
        return const Color(0xFF1565C0);
      case 'accepted':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'cancelled':
        return const Color(0xFFE65100);
      case 'chat':
        return const Color(0xFF6A1B9A);
      case 'reminder':
      case 'starting_soon':
        return const Color(0xFFF57F17);
      default:
        return const Color(0xFF6F6F72);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}

// ─── Shimmer Tile ─────────────────────────────────────────────────────────────

class _ShimmerTile extends StatefulWidget {
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final shimmerColor = Color.lerp(
          const Color(0xFFEEEEEE),
          const Color(0xFFDDDDDD),
          _anim.value,
        )!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAE5DD)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 180,
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
