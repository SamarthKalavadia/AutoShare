import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/providers.dart';
import '../auth/presentation/controllers/onboarding_controller.dart';
import '../auth/presentation/controllers/auth_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  bool _isAnimationComplete = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _iconScaleAnim;
  late final Animation<double> _iconFadeAnim;
  late final Animation<double> _titleFadeAnim;
  late final Animation<Offset> _titleSlideAnim;
  late final Animation<double> _taglineFadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2200,
      ), // Adjusted for smooth, unhurried feel
    );

    // App icon begins slightly scaled down and transparent (0.10s to 0.70s equivalent out of 2.2s -> 4.5% to 32%)
    _iconScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.045, 0.32, curve: Curves.easeOutCubic),
      ),
    );
    _iconFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.045, 0.32, curve: Curves.easeIn),
      ),
    );

    // Brand name appears (e.g. 0.70s to 1.3s -> 32% to 59%)
    _titleSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.32, 0.59, curve: Curves.easeOutCubic),
          ),
        );
    _titleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.32, 0.59, curve: Curves.easeIn),
      ),
    );

    // Tagline fades in (e.g. 1.2s to 1.8s -> 55% to 82%)
    _taglineFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.55, 0.82, curve: Curves.easeIn),
      ),
    );

    _animCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimationComplete = true;
        _navigateIfReady();
      }
    });

    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProvidersAndNavigate();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _checkProvidersAndNavigate() {
    final authAsync = ref.read(authStateProvider);
    final onboardingAsync = ref.read(onboardingCompletedProvider);
    final authControllerAsync = ref.read(authControllerProvider);

    if (authAsync.isLoading ||
        onboardingAsync.isLoading ||
        authControllerAsync.isLoading) {
      ref.listenManual(authStateProvider, (_, next) {
        if (!next.isLoading) _navigateIfReady();
      }, fireImmediately: false);
      ref.listenManual(onboardingCompletedProvider, (_, next) {
        if (!next.isLoading) _navigateIfReady();
      }, fireImmediately: false);
      ref.listenManual(authControllerProvider, (_, next) {
        if (!next.isLoading) _navigateIfReady();
      }, fireImmediately: false);
      return;
    }

    _navigateIfReady();
  }

  void _navigateIfReady() {
    if (!mounted || _hasNavigated || !_isAnimationComplete) return;

    final authAsync = ref.read(authStateProvider);
    final onboardingAsync = ref.read(onboardingCompletedProvider);
    final authControllerAsync = ref.read(authControllerProvider);

    if (authAsync.isLoading ||
        onboardingAsync.isLoading ||
        authControllerAsync.isLoading)
      return;

    _hasNavigated = true;

    final User? user = authAsync.value;
    final bool onboardingDone = onboardingAsync.value ?? false;

    if (user == null) {
      if (onboardingDone) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    } else {
      if (!user.emailVerified) {
        context.go('/email-verification');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final onboardingAsync = ref.watch(onboardingCompletedProvider);
    final authControllerAsync = ref.watch(authControllerProvider);

    final allResolved =
        !authAsync.isLoading &&
        !onboardingAsync.isLoading &&
        !authControllerAsync.isLoading;
    if (allResolved && !_hasNavigated && _isAnimationComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateIfReady());
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Using deep dark for dark mode, and existing surface for light mode
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : theme.colorScheme.surface;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6F6F72);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _iconScaleAnim.value,
                  child: Opacity(
                    opacity: _iconFadeAnim.value,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/appicon.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _titleSlideAnim,
                  child: Opacity(
                    opacity: _titleFadeAnim.value,
                    child: Text(
                      'AutoShare',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _taglineFadeAnim.value,
                  child: Text(
                    'Smart & Safe Ride Sharing',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: subtitleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
