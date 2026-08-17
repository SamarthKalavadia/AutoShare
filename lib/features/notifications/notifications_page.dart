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
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (grouped.today.isNotEmpty) ...[
          const _SectionHeader(label: 'TODAY'),
          ...grouped.today.map((n) => _NotificationTile(notification: n)),
        ],
        if (grouped.yesterday.isNotEmpty) ...[
          const _SectionHeader(label: 'YESTERDAY'),
          ...grouped.yesterday.map((n) => _NotificationTile(notification: n)),
        ],
        if (grouped.older.isNotEmpty) ...[
          const _SectionHeader(label: 'EARLIER'),
          ...grouped.older.map((n) => _NotificationTile(notification: n)),
        ],
      ],
    );
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
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.isRead;

    final iconBg = _iconBgForType(notification.type, isDark);
    final iconColor = _iconColorForType(notification.type, isDark);
    final icon = _iconForType(notification.type);

    final bgColor = isUnread
        ? (isDark ? const Color(0xFF2A2820) : const Color(0xFFFFFDF5))
        : Colors.transparent;

    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF3F3F3);

    final titleColor = isDark ? Colors.white : const Color(0xFF121212);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF6F6F72);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              if (isUnread) ...[
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
