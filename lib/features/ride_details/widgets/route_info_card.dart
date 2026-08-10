import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/ride_model.dart';

class RouteInfoCard extends StatelessWidget {
  final RideModel ride;

  const RouteInfoCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFEAE5DD);
    const mutedText = Color(0xFF6F6F72);
    const successColor = Color(0xFF2E7D32);
    const dangerColor = Color(0xFFD32F2F);

    final dateStr = DateFormat('EEE, d MMM yyyy').format(ride.departureTime);
    final timeStr = DateFormat('h:mm a').format(ride.departureTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(color: Color(0x0A121212), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Route',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: successColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x332E7D32), blurRadius: 4),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFFD32F2F)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: dangerColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33D32F2F), blurRadius: 4),
                          ],
                        ),
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
                        color: successColor,
                      ),
                      const SizedBox(height: 20),
                      _LocationLabel(
                        label: 'Destination',
                        value: ride.destination,
                        color: dangerColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEAE5DD)),
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

          if (ride.distance.isNotEmpty || ride.estimatedDuration.isNotEmpty) ...[
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
                if (ride.distance.isNotEmpty && ride.estimatedDuration.isNotEmpty)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.withAlpha(180),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '—',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6F6F72)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121212),
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
