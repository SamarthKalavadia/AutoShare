import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers/driver_provider.dart';

class DriverDirectoryPage extends ConsumerWidget {
  const DriverDirectoryPage({super.key});

  String _formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }

  Future<void> _makePhoneCall(String phone) async {
    final formattedPhone = '+91$phone';
    final Uri url = Uri.parse('tel:$formattedPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch dialer for $formattedPhone');
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final formattedPhone = '+91$phone';
    final Uri url = Uri.parse('https://wa.me/$formattedPhone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Please check if it is installed.'),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    const primaryColor = Color(0xFFF6C000);

    final driversAsync = ref.watch(driverDirectoryListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: blackColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Driver Directory',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: blackColor,
              ),
            ),

          ],
        ),
      ),
      body: driversAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error loading drivers: $error',
              style: GoogleFonts.inter(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (drivers) {
          if (drivers.isEmpty) {
            return Center(
              child: Text(
                'No drivers available',
                style: GoogleFonts.inter(fontSize: 16, color: mutedText),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.1),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: blackColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPhoneNumber(driver.phone),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: FilledButton.icon(
                                onPressed: () => _makePhoneCall(driver.phone),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF222222) : Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.call, size: 18, color: Colors.white),
                                label: const Text(
                                  'Call',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: FilledButton.icon(
                                onPressed: () => _openWhatsApp(context, driver.phone),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.message_outlined, size: 18, color: Colors.white),
                                label: const Text(
                                  'WhatsApp',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
