import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/providers.dart';
import '../auth/presentation/controllers/onboarding_controller.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import '../auth/presentation/widgets/animated_logo.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Kick off the minimum display delay and then check providers.
    // We use addPostFrameCallback so the first build has run before we call ref.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitAndNavigate();
    });
  }

  Future<void> _waitAndNavigate() async {
    // Minimum splash display time.
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted || _hasNavigated) return;
    _navigate();
  }

  void _navigate() {
    if (!mounted || _hasNavigated) return;

    final authAsync = ref.read(authStateProvider);
    final onboardingAsync = ref.read(onboardingCompletedProvider);
    final authControllerAsync = ref.read(authControllerProvider);

    // If any provider is still loading we listen and retry when they settle.
    if (authAsync.isLoading || onboardingAsync.isLoading || authControllerAsync.isLoading) {
      ref.listenManual(
        authStateProvider,
        (_, next) {
          if (!next.isLoading) _navigate();
        },
        fireImmediately: false,
      );
      ref.listenManual(
        onboardingCompletedProvider,
        (_, next) {
          if (!next.isLoading) _navigate();
        },
        fireImmediately: false,
      );
      ref.listenManual(
        authControllerProvider,
        (_, next) {
          if (!next.isLoading) _navigate();
        },
        fireImmediately: false,
      );
      return;
    }

    // Providers have resolved — navigate exactly once.
    _hasNavigated = true;

    final User? user = authAsync.value;
    final bool onboardingDone = onboardingAsync.value ?? false;

    if (user == null) {
      // No authenticated user.
      if (onboardingDone) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    } else {
      // User is authenticated — check email verification.
      if (!user.emailVerified) {
        context.go('/email-verification');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers so the widget rebuilds when they resolve,
    // then attempt navigation on each rebuild (guarded by _hasNavigated).
    final authAsync = ref.watch(authStateProvider);
    final onboardingAsync = ref.watch(onboardingCompletedProvider);
    final authControllerAsync = ref.watch(authControllerProvider);

    final allResolved = !authAsync.isLoading && !onboardingAsync.isLoading && !authControllerAsync.isLoading;
    if (allResolved && !_hasNavigated) {
      // Schedule navigation on the next frame (build is ongoing right now).
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const AnimatedLogo(size: 110),
              const SizedBox(height: 28),
              Text(
                'AutoShare',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart & Safe Ride Sharing',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
