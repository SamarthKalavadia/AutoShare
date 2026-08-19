import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'privacy_policy_page.dart';

class PrivacySettingsPage extends ConsumerWidget {
  const PrivacySettingsPage({super.key});

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD32F2F),
              ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action is permanent and will delete all your data, rides, and settings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF6F6F72),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                ),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor =
        theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF));
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final mutedText = isDark ? Colors.white70 : const Color(0xFF6F6F72);

    Widget buildSectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: mutedText,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    Widget buildInfoTile(IconData icon, String title, String subtitle) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy'),
        centerTitle: false,
        backgroundColor: backgroundColor,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          buildSectionHeader('Privacy & Data'),
          buildInfoTile(
            Icons.person_outline,
            'Personal Information',
            'Your personal information is used to maintain your AutoShare account and provide our services securely.',
          ),
          buildInfoTile(
            Icons.location_on_outlined,
            'Location',
            'Location data is used for selecting pickup/drop-off points, finding nearby rides, and enhancing your travel experience.',
          ),
          buildInfoTile(
            Icons.notifications_none,
            'Notifications',
            'Notifications keep you updated on ride requests, ride status, chat messages, and important account alerts.',
          ),
          buildInfoTile(
            Icons.badge_outlined,
            'Profile Information',
            'Your name, profile picture, and verified details are used to build trust within the AutoShare community.',
          ),
          
          buildSectionHeader('Communications'),
          buildInfoTile(
            Icons.chat_bubble_outline,
            'Chat & Messages',
            'In-app chat allows you to safely communicate with your ride partners without sharing your personal phone number.',
          ),

          buildSectionHeader('Data Control'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Privacy Policy',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: mutedText),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Delete Account',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD32F2F),
              ),
            ),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
