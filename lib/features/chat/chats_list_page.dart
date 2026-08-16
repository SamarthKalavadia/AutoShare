import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../my_rides/providers/my_rides_provider.dart';
import '../chat/providers/chat_provider.dart';

class ChatsListPage extends ConsumerWidget {
  const ChatsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesState = ref.watch(myRidesProvider);

    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Chats',
          style: theme.textTheme.titleLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ridesState.when(
        data: (rides) {
          final activeChats = rides.where((r) {
            final status = r.displayStatus;
            return status == 'active' ||
                status == 'joined' ||
                status == 'completed';
          }).toList();

          if (activeChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active chats yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeChats.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rideData = activeChats[index];
              return _ChatCard(data: rideData);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading chats: $err')),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final MyRideData data;

  const _ChatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final textColor = theme.colorScheme.onSurface;
    final subtextColor = isDark ? Colors.white60 : Colors.grey[600];

    final isDriver = data.role == 'driver';
    // Ideally we should know the exact participant, but for now we link to the ride chat
    // If driver, we don't know the exact passenger here unless we query the requests.
    // For simplicity, we just pass the ride owner id.
    final participantUid = isDriver
        ? data.ride.driverId
        : (data.request?.requesterUid ?? '');
    final participantName = isDriver ? data.ride.driverName : 'Driver';

    return InkWell(
      onTap: () {
        context.push(
          '/chat',
          extra: ChatPageArgs(
            ride: data.ride,
            otherParticipantUid: participantUid,
            otherParticipantName: participantName,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: borderColor, width: 1.1) : null,
          boxShadow: isDark
              ? []
              : const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(
                Icons.person,
                color: isDark ? Colors.white : const Color(0xFF121212),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.ride.boardingLocation} → ${data.ride.destination}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDriver
                        ? 'Your Ride'
                        : 'Ride with ${data.ride.driverName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
