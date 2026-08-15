import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/result.dart';
import 'providers/create_ride_provider.dart';
import 'widgets/create_ride_form.dart';

class CreateRidePage extends ConsumerWidget {
  const CreateRidePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    const successColor = Color(0xFF2E7D32);
    const dangerColor = Color(0xFFD32F2F);

    final state = ref.watch(createRideProvider);
    final notifier = ref.read(createRideProvider.notifier);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: blackColor),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Create Ride',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: blackColor,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer your empty seats and travel smarter.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // The Form
                      const CreateRideForm(),
                      
                      // Ride Information Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFBF8F1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: blackColor, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Good to know',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: blackColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              icon: Icons.check_circle_rounded,
                              iconColor: successColor,
                              text: 'Contact number remains hidden until ride request is accepted',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.check_circle_rounded,
                              iconColor: successColor,
                              text: 'Only registered AutoShare users can request rides',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.schedule_rounded,
                              iconColor: primaryColor,
                              text: 'Ride expires automatically after departure time',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.cancel_rounded,
                              iconColor: dangerColor,
                              text: 'Users can cancel before departure',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              // Publish Button Sticky Bottom
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final result = await notifier.publishRide();
                            if (!context.mounted) return;
                            
                            if (result is Success<String>) {
                              _showSuccessDialog(context, ref);
                            } else if (result is Failure<String>) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: dangerColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: blackColor,
                      disabledBackgroundColor: primaryColor.withAlpha(100),
                      disabledForegroundColor: blackColor.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: state.isValid ? 4 : 0,
                    ),
                    child: state.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(blackColor),
                            ),
                          )
                        : Text(
                            'Create Ride',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF5ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ride Created\nSuccessfully',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF121212),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your ride is now available for nearby passengers travelling in the same direction.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6F6F72),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          ref.read(createRideProvider.notifier).reset();
                          if (Navigator.of(context, rootNavigator: true).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                          context.go('/my-rides');
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF121212),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'View My Ride',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: () {
                          ref.read(createRideProvider.notifier).reset();
                          if (Navigator.of(context, rootNavigator: true).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                          context.go('/home');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6F6F72),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4C4C4F),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
