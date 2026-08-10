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
    const primaryColor = Color(0xFFF6C000);
    const blackColor = Color(0xFF121212);
    const borderColor = Color(0xFFEAE5DD);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x144CAF50),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Text(
                'Ride Accepted',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Contact details are now visible.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6F6F72),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: borderColor, height: 1),
          ),
          
          // Details
          _DetailRow(icon: Icons.person_outline, label: 'Driver', value: driver.name),
          const SizedBox(height: 12),
          _DetailRow(icon: Icons.person_outline, label: 'Passenger', value: passenger.name),
          if (ride.vehicleNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.directions_car_outlined, label: 'Vehicle', value: ride.vehicleNumber),
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
                  label: Text('Call', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8F7F4),
                    foregroundColor: blackColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/chat', extra: ChatPageArgs(
                      ride: ride,
                      otherParticipantUid: driver.uid,
                      otherParticipantName: driver.name,
                    ));
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('Chat', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: blackColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final cleanPhone = driver.phone.replaceAll(RegExp(r'[^\d+]'), '');
                    _launchUrl('https://wa.me/$cleanPhone');
                  },
                  icon: const Icon(Icons.message_outlined, size: 18), // WhatsApp placeholder icon
                  label: Text('WhatsApp', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6F6F72)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6F6F72),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF121212),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
