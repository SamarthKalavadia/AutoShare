import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../features/splash/splash_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/email_verification_page.dart';
import '../../features/auth/presentation/screens/profile_completion_page.dart';
import '../../features/home/presentation/screens/home_page.dart';
import '../../features/ride_details/create_ride_page.dart';
import '../../features/ride_details/ride_details_page.dart';
import '../../features/search/search_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/driver_directory/driver_directory_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/requests/requests_page.dart';
import '../../features/my_rides/my_rides_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../data/models/ride_model.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    observers: [
      FirebaseAnalyticsObserver(analytics: _analytics),
    ],
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(
        path: '/email-verification',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const EmailVerificationPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),
      GoRoute(path: '/profile-completion', builder: (context, state) => const ProfileCompletionPage()),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),
      GoRoute(path: '/search-ride', builder: (context, state) => const SearchPage()),
      GoRoute(path: '/create-ride', builder: (context, state) => const CreateRidePage()),
      GoRoute(
        path: '/ride-details',
        builder: (context, state) {
          final ride = state.extra as RideModel;
          return RideDetailsPage(ride: ride);
        },
      ),
      GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
      GoRoute(
        path: '/public-profile',
        builder: (context, state) {
          final userId = state.extra as String;
          return PublicProfilePage(userId: userId);
        },
      ),
      GoRoute(path: '/driver-directory', builder: (context, state) => const DriverDirectoryPage()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
      GoRoute(path: '/incoming-requests', builder: (context, state) => const RequestsPage()),
      GoRoute(path: '/my-rides', builder: (context, state) => const MyRidesPage()),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final args = state.extra as ChatPageArgs;
          return ChatPage(args: args);
        },
      ),
    ],
  );
}
