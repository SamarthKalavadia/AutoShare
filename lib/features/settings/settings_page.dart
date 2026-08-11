import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../auth/presentation/controllers/auth_controller.dart';
import 'providers/settings_provider.dart';
import 'security_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFD32F2F))),
        content: Text(
          'Are you sure you want to delete your account? This action is permanent and will delete all your data, rides, and settings.',
          style: GoogleFonts.inter(color: const Color(0xFF6F6F72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))),
              );
              
              try {
                await ref.read(authControllerProvider.notifier).deleteAccount();
              } catch (_) {
              } finally {
                if (context.mounted) {
                  if (Navigator.of(context, rootNavigator: true).canPop()) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                  context.go('/login');
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildSectionTitle('Preferences', context),
          _buildSwitchTile(
            context: context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            value: settings.isDarkMode,
            onChanged: notifier.toggleDarkMode,
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.notifications_none_rounded,
            title: 'Push Notifications',
            value: settings.pushNotifications,
            onChanged: notifier.togglePushNotifications,
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            value: settings.emailNotifications,
            onChanged: notifier.toggleEmailNotifications,
          ),
          _buildListTile(
            context: context,
            icon: Icons.language_rounded,
            title: 'Language',
            trailingText: settings.language,
            onTap: () {
              // Placeholder for language picker
            },
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Security & Privacy', context),
          _buildListTile(
            context: context,
            icon: Icons.security_rounded,
            title: 'Security',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsPage()));
            },
          ),
          _buildListTile(
            context: context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Settings',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('About', context),
          _buildListTile(context: context, icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () {}),
          _buildListTile(context: context, icon: Icons.description_outlined, title: 'Terms & Conditions', onTap: () {}),
          _buildListTile(context: context, icon: Icons.shield_outlined, title: 'Privacy Policy', onTap: () {}),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  await ref.read(authControllerProvider.notifier).logout();
                } catch (_) {
                } finally {
                  if (context.mounted) {
                    if (Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    context.go('/login');
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: borderColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Logout', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _showDeleteAccountDialog(context, ref),
              child: Text(
                'Delete Account',
                style: GoogleFonts.inter(color: const Color(0xFFD32F2F), fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white60 : const Color(0xFF6F6F72),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
      secondary: Icon(icon, color: textColor, size: 22),
      activeTrackColor: const Color(0xFFF6C000),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
      leading: Icon(icon, color: textColor, size: 22),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText, style: GoogleFonts.inter(color: isDark ? Colors.white60 : const Color(0xFF6F6F72), fontSize: 14)),
          if (trailingText != null) const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : const Color(0xFF8E8E93), size: 20),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
