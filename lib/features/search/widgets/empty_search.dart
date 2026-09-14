import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptySearch extends StatelessWidget {
  const EmptySearch({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blackColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final iconBg = isDark ? const Color(0xFF1F2D26) : const Color(0xFFF0F7F4);
    final mutedText = isDark ? const Color(0xFFA0B2AA) : const Color(0xFF6B7E75);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(
              Icons.search_off_rounded,
              size: 56,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No rides found',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: blackColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try changing your filters or search another route.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: mutedText),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => context.push('/create-ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 2,
              ),
              child: Text(
                'Create Ride',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
