import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';

import 'core/services/notification_service.dart';
import 'core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/settings/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService().init();

  // Enable Offline Persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kDebugMode) {
    // In development/debug mode, output errors directly to the console for fast debugging
    FlutterError.onError = FlutterError.dumpErrorToConsole;
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('---------------- UNCAUGHT ERROR ----------------');
      debugPrint('$error');
      debugPrint('$stack');
      debugPrint('------------------------------------------------');
      return true;
    };
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } catch (_) {}
  } else {
    // In production/release mode, pass uncaught errors to Crashlytics safely
    FlutterError.onError = (details) {
      try {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } catch (e) {
        debugPrint('Crashlytics recordFlutterFatalError error: $e');
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (e) {
        debugPrint('Crashlytics recordError error: $e');
      }
      return true;
    };
  }

  runApp(const ProviderScope(child: AutoShareApp()));
}

class AutoShareApp extends ConsumerWidget {
  const AutoShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AutoShare',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
    );
  }
}
