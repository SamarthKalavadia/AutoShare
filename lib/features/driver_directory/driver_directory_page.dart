import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/driver_model.dart';
import 'providers/driver_provider.dart';
import '../../shared/utils/avatar_utils.dart';

class DriverDirectoryPage extends ConsumerStatefulWidget {
  const DriverDirectoryPage({super.key});

  @override
  ConsumerState<DriverDirectoryPage> createState() => _DriverDirectoryPageState();
}

class _DriverDirectoryPageState extends ConsumerState<DriverDirectoryPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final blackColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    final filteredAsync = ref.watch(filteredDriversProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: blackColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Directory',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: blackColor,
              ),
            ),
            Text(
              'Trusted local auto drivers.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFF6C000)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: GoogleFonts.inter(color: const Color(0xFF6F6F72))),
              ),
              data: (drivers) {
                if (drivers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car_outlined,
                            size: 64, color: Color(0xFFCCCCCC)),
                        const SizedBox(height: 16),
                        Text(
                          'No drivers available',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6F6F72),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: drivers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _DriverCard(
                      driver: drivers[index],
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Driver Card ───────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final int index;

  const _DriverCard({required this.driver, required this.index});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open: $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const blackColor = Color(0xFF121212);
    const mutedText = Color(0xFF6F6F72);
    const borderColor = Color(0xFFEAE5DD);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F121212),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {}, // Future: open detail page
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  _DriverAvatar(driver: driver),
                  const SizedBox(width: 12),
                  // ── Info ────────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row
                        Text(
                          driver.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: blackColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Phone number
                        Text(
                          '+${driver.phoneNumber.replaceAll('\nHome', '')}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: 'Call',
                                icon: Icons.call_rounded,
                                bgColor: blackColor,
                                fgColor: Colors.white,
                                onTap: () {
                                  final cleanPhone = driver.phoneNumber.split('\n').first.trim();
                                  _launchUrl(context, 'tel:+$cleanPhone');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActionButton(
                                label: 'WhatsApp',
                                icon: Icons.chat_rounded,
                                bgColor: const Color(0xFF25D366),
                                fgColor: Colors.white,
                                onTap: () {
                                  final cleanPhone = driver.phoneNumber.split('\n').first.trim();
                                  _launchUrl(context, 'https://wa.me/$cleanPhone');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Driver Avatar ─────────────────────────────────────────────────────────────

class _DriverAvatar extends StatelessWidget {
  final DriverModel driver;
  const _DriverAvatar({required this.driver});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: getAvatarImageProvider(driver.profileImage) != null
            ? Image(
                image: getAvatarImageProvider(driver.profileImage)!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _Initials(name: driver.name),
              )
            : _Initials(name: driver.name),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFFF8F3E7),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121212),
          ),
        ),
      ),
    );
  }
}


// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
