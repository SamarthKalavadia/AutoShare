import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/providers/chat_provider.dart';
import '../../ride_details/providers/driver_profile_provider.dart';
import '../providers/my_rides_provider.dart';

class MyRideCard extends ConsumerWidget {
  final MyRideData data;
  final VoidCallback? onView;
  final VoidCallback? onCancel;
  final VoidCallback? onTrack;

  const MyRideCard({
    super.key,
    required this.data,
    this.onView,
    this.onCancel,
    this.onTrack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);

    final ride = data.ride;
    final status = data.displayStatus;
    
    // Status color mapping
    Color badgeColor;
    Color badgeTextColor = Colors.white;
    String statusText = status.toUpperCase();

    switch (status) {
      case 'active':
      case 'pending':
        badgeColor = const Color(0xFFF6C000); // Primary Yellow
        badgeTextColor = blackColor;
        break;
      case 'joined':
      case 'completed':
        badgeColor = const Color(0xFF4CAF50); // Green
        break;
      case 'cancelled':
      case 'rejected':
      default:
        badgeColor = const Color(0xFF9E9E9E); // Grey
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: blackColor.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Role and Status ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    data.role == 'driver' ? Icons.directions_car : Icons.person,
                    size: 16,
                    color: mutedText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.role == 'driver' ? 'Driver' : 'Passenger',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mutedText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Route Info ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.route_outlined, color: mutedText, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ride.boardingLocation} → ${ride.destination}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: blackColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(ride.departureTime),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: borderColor, height: 1),
          ),

          // ── Bottom: Fare & Seats ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 16, color: blackColor),
                  Text(
                    '${ride.farePerSeat.toInt()} / seat',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.event_seat, size: 16, color: mutedText),
                  const SizedBox(width: 4),
                  Text(
                    data.role == 'passenger'
                        ? '${data.request?.requestedSeats ?? 1} requested'
                        : '${ride.availableSeats} available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Actions ──
          const SizedBox(height: 20),
          Row(
            children: [
              if (onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: borderColor, width: 2),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8F7F4),
                    foregroundColor: blackColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'View Ride',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (data.role == 'passenger' && data.displayStatus == 'joined') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final driverAsync = ref.watch(userProfileProvider(ride.driverId));
                      return driverAsync.when(
                        data: (driver) {
                          return Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.push('/chat', extra: ChatPageArgs(
                                      ride: ride,
                                      otherParticipantUid: driver.uid,
                                      otherParticipantName: driver.name,
                                    ));
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                  label: const SizedBox.shrink(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF6C000), // Primary Yellow
                                    foregroundColor: blackColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final url = Uri.parse('tel:${driver.phone}');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.phone_outlined, size: 16),
                                  label: const SizedBox.shrink(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF8F7F4),
                                    foregroundColor: blackColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final cleanPhone = driver.phone.replaceAll(RegExp(r'[^\d+]'), '');
                                    final url = Uri.parse('https://wa.me/$cleanPhone');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.message_outlined, size: 16),
                                  label: const SizedBox.shrink(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (err, stack) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
              ],
              if (onTrack != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onTrack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blackColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Track Status',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
