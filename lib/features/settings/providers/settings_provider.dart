import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isDarkMode;
  final bool useSystemTheme;
  final bool pushNotifications;
  final bool emailNotifications;
  final String language;

  const SettingsState({
    this.isDarkMode = false,
    this.useSystemTheme = true,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.language = 'English',
  });

  ThemeMode get themeMode {
    if (useSystemTheme) {
      return ThemeMode.system;
    }
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Locale get locale {
    switch (language) {
      case 'Hindi':
        return const Locale('hi');
      case 'Gujarati':
        return const Locale('gu');
      case 'English':
      default:
        return const Locale('en');
    }
  }

  SettingsState copyWith({
    bool? isDarkMode,
    bool? useSystemTheme,
    bool? pushNotifications,
    bool? emailNotifications,
    String? language,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> with WidgetsBindingObserver {
  static const _keyDarkMode = 'settings_is_dark_mode';
  static const _keyUseSystemTheme = 'settings_use_system_theme';
  static const _keyPushNotif = 'settings_push_notifications';
  static const _keyEmailNotif = 'settings_email_notifications';
  static const _keyLanguage = 'settings_language';

  Brightness? _lastPlatformBrightness;

  @override
  SettingsState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    final currentBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _lastPlatformBrightness = currentBrightness;
    final isSystemDark = currentBrightness == Brightness.dark;

    _loadFromPrefs();

    return SettingsState(
      isDarkMode: isSystemDark,
      useSystemTheme: true,
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _lastPlatformBrightness = currentBrightness;
      final isSystemDark = currentBrightness == Brightness.dark;

      final useSystem = prefs.getBool(_keyUseSystemTheme) ?? true;
      final bool isDark;
      if (useSystem) {
        isDark = isSystemDark;
      } else {
        isDark = prefs.getBool(_keyDarkMode) ?? isSystemDark;
      }

      final push = prefs.getBool(_keyPushNotif) ?? true;
      final email = prefs.getBool(_keyEmailNotif) ?? true;
      final lang = prefs.getString(_keyLanguage) ?? 'English';

      state = SettingsState(
        isDarkMode: isDark,
        useSystemTheme: useSystem,
        pushNotifications: push,
        emailNotifications: email,
        language: lang,
      );
    } catch (_) {}
  }

  @override
  void didChangePlatformBrightness() {
    _syncWithSystemBrightness();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWithSystemBrightness();
    }
  }

  void _syncWithSystemBrightness() {
    final currentBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isSystemDark = currentBrightness == Brightness.dark;

    if (state.useSystemTheme || currentBrightness != _lastPlatformBrightness) {
      _lastPlatformBrightness = currentBrightness;
      state = state.copyWith(
        isDarkMode: isSystemDark,
        useSystemTheme: true,
      );
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(_keyUseSystemTheme, true);
        prefs.setBool(_keyDarkMode, isSystemDark);
      }).catchError((_) {});
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    state = state.copyWith(
      isDarkMode: value,
      useSystemTheme: false,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDarkMode, value);
      await prefs.setBool(_keyUseSystemTheme, false);
    } catch (_) {}
  }

  Future<void> togglePushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPushNotif, value);
    } catch (_) {}
  }

  Future<void> toggleEmailNotifications(bool value) async {
    state = state.copyWith(emailNotifications: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEmailNotif, value);
    } catch (_) {}
  }

  Future<void> setLanguage(String value) async {
    state = state.copyWith(language: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, value);
    } catch (_) {}
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
