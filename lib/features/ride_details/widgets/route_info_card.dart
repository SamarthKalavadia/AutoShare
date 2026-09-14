import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/ride_model.dart';

class RouteInfoCard extends StatelessWidget {
  final RideModel ride;

  const RouteInfoCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark
        ? const Color(0xFF2D3F37)
        : const Color(0xFFE3EBE6);
    final mutedText = isDark ? const Color(0xFFA0B2AA) : const Color(0xFF6B7E75);
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF18221D) : Colors.white);

    const pickupColor = Color(0xFFE5A93C);
    const dropColor = Color(0xFFE53935);

    final dateStr = DateFormat('EEE, d MMM yyyy').format(ride.departureTime);
    final timeStr = DateFormat('h:mm a').format(ride.departureTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: borderColor, width: 1.1) : null,
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Color(0x0A121212),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'ROUTE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: mutedText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),

          // Route timeline
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline column
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.adjust_rounded,
                        color: pickupColor,
                        size: 16,
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: borderColor,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: dropColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Location text column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocationLabel(
                        label: 'Boarding',
                        value: ride.boardingLocation,
                        color: pickupColor,
                      ),
                      const SizedBox(height: 20),
                      _LocationLabel(
                        label: 'Destination',
                        value: ride.destination,
                        color: dropColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: borderColor,
          ),
          const SizedBox(height: 16),

          // Date / Time / Duration row
          Row(
            children: [
              Expanded(
                child: _MetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: dateStr,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetaChip(
                  icon: Icons.access_time_rounded,
                  label: 'Departure',
                  value: timeStr,
                ),
              ),
            ],
          ),

          if (ride.distance.isNotEmpty ||
              ride.estimatedDuration.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (ride.distance.isNotEmpty)
                  Expanded(
                    child: _MetaChip(
                      icon: Icons.straighten_rounded,
                      label: 'Distance',
                      value: ride.distance,
                    ),
                  ),
                if (ride.distance.isNotEmpty &&
                    ride.estimatedDuration.isNotEmpty)
                  const SizedBox(width: 12),
                if (ride.estimatedDuration.isNotEmpty)
                  Expanded(
                    child: _MetaChip(
                      icon: Icons.timer_rounded,
                      label: 'Est. Duration',
                      value: ride.estimatedDuration,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LocationLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blackColor = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isNotEmpty ? value : '—',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: blackColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;
    final chipBg = isDark ? const Color(0xFF1F2D26) : const Color(0xFFF0F7F4);
    final chipBorder = isDark ? const Color(0xFF2E4D3D) : const Color(0xFFC4E3D4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isDark ? const Color(0xFFA0B2AA) : const Color(0xFF6B7E75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
