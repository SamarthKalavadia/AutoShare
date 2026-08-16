import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/presentation/controllers/auth_controller.dart';
import '../../core/utils/result.dart';

class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() =>
      _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  bool _isResetting = false;

  void _showResetConfirmation(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Send a password reset link to:\n\n$email',
          style: GoogleFonts.inter(color: const Color(0xFF6F6F72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendResetLink(email);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF121212),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetLink(String email) async {
    setState(() => _isResetting = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(email);
    setState(() => _isResetting = false);

    if (mounted) {
      if (result is Success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog((result as Failure).message);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.mark_email_read_rounded,
          size: 48,
          color: Color(0xFF2E7D32),
        ),
        title: Text(
          'Email Sent',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Password reset email sent successfully.\n\nPlease check your inbox and follow the instructions to create a new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: const Color(0xFF6F6F72)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF121212),
              minimumSize: const Size(120, 48),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Error',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: const Color(0xFFD32F2F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);
    final blackColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: blackColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Security',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: blackColor,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle('Authentication'),
                _buildListTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  subtitle: 'Send a reset link to your email',
                  onTap: () => _showResetConfirmation(user.email),
                  trailing: _isResetting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF8E8E93),
                        ),
                ),
                const Divider(height: 1, color: Color(0xFFEAE5DD)),
                _buildListTile(
                  icon: Icons.verified_user_rounded,
                  title: 'Email Verification Status',
                  subtitle: user.emailVerified ? 'Verified' : 'Unverified',
                  trailing: Icon(
                    user.emailVerified
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: user.emailVerified
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F),
                  ),
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('Session'),
                _buildListTile(
                  icon: Icons.devices_rounded,
                  title: 'Current Session',
                  subtitle: 'Logged in as ${user.email}',
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6F6F72),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDE9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF121212), size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF121212),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6F6F72),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
