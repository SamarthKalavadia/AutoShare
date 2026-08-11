import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/result.dart';
import '../../core/utils/snackbar_helper.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/widgets/loading_button.dart';
import 'presentation/widgets/secondary_button.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState
    extends ConsumerState<EmailVerificationPage> {
  Timer? _pollingTimer;
  bool _isResending = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkVerificationStatus(showToast: false);
    });
  }

  Future<void> _checkVerificationStatus({bool showToast = true}) async {
    if (_isChecking) return;
    _isChecking = true;

    final user = await ref.read(authControllerProvider.notifier).reloadUser();
    _isChecking = false;

    if (!mounted) return;

    if (user != null && user.emailVerified) {
      _pollingTimer?.cancel();
      context.go('/home');
    } else if (showToast) {
      SnackbarHelper.show(
        context,
        'Email not verified yet. Please check your inbox.',
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .sendEmailVerification();

    setState(() => _isResending = false);

    if (!mounted) return;

    if (result is Success<void>) {
      SnackbarHelper.show(
        context,
        'Verification link resent! Please check your email.',
      );
    } else if (result is Failure<void>) {
      SnackbarHelper.show(context, result.message);
    }
  }

  Future<void> _handleLogout() async {
    _pollingTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } catch (_) {
    } finally {
      if (mounted) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    size: 70,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Verify Your Email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We've sent a verification link to your email address. Please open your inbox and click the link to verify.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Automatically waiting for verification...',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // "I've Verified" Button
              LoadingButton(
                text: "I've Verified",
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => _checkVerificationStatus(showToast: true),
              ),
              const SizedBox(height: 12),

              // Resend Email Button
              SecondaryButton(
                text: _isResending ? 'Sending...' : 'Resend Verification Email',
                icon: Icons.refresh_rounded,
                onPressed: _isResending ? null : _resendVerificationEmail,
              ),
              const SizedBox(height: 12),

              // Logout Button
              TextButton(
                onPressed: _handleLogout,
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
