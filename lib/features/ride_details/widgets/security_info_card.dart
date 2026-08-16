import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/ride_model.dart';
import '../../../data/models/user_model.dart';
import '../../chat/providers/chat_provider.dart';

class SecurityInfoCard extends ConsumerWidget {
  final RideModel ride;
  final UserModel driver;
  final UserModel passenger;

  const SecurityInfoCard({
    super.key,
    required this.ride,
    required this.driver,
    required this.passenger,
  });

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final successColor = isDark
        ? const Color(0xFF81C784)
        : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: successColor, width: 1.5),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: successColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_rounded, color: successColor),
              const SizedBox(width: 8),
              Text(
                'Ride Accepted',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Contact details are now visible.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white60 : const Color(0xFF6F6F72),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: isDark ? Colors.white10 : borderColor,
              height: 1,
            ),
          ),

          // Details
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Driver',
            value: driver.name,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Passenger',
            value: passenger.name,
          ),
          if (ride.vehicleNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.directions_car_outlined,
              label: 'Vehicle',
              value: ride.vehicleNumber,
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _launchUrl('tel:${driver.phone}');
                  },
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF28282A)
                        : const Color(0xFFF8F7F4),
                    foregroundColor: blackColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      '/chat',
                      extra: ChatPageArgs(
                        ride: ride,
                        otherParticipantUid: driver.uid,
                        otherParticipantName: driver.name,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: const Color(0xFF121212),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final cleanPhone = driver.phone.replaceAll(
                      RegExp(r'[^\d+]'),
                      '',
                    );
                    _launchUrl('https://wa.me/$cleanPhone');
                  },
                  icon: const Icon(
                    Icons.message_outlined,
                    size: 18,
                  ), // WhatsApp placeholder icon
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final blackColor = theme.colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 16, color: mutedText),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: mutedText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: blackColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
