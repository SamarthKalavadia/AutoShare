import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isDarkMode;
  final bool pushNotifications;
  final bool emailNotifications;
  final String language;

  const SettingsState({
    this.isDarkMode = false,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.language = 'English',
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? pushNotifications,
    bool? emailNotifications,
    String? language,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _keyDarkMode = 'settings_is_dark_mode';
  static const _keyPushNotif = 'settings_push_notifications';
  static const _keyEmailNotif = 'settings_email_notifications';
  static const _keyLanguage = 'settings_language';

  @override
  SettingsState build() {
    _loadFromPrefs();
    return const SettingsState();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_keyDarkMode) ?? false;
      final push = prefs.getBool(_keyPushNotif) ?? true;
      final email = prefs.getBool(_keyEmailNotif) ?? true;
      final lang = prefs.getString(_keyLanguage) ?? 'English';
      state = SettingsState(
        isDarkMode: isDark,
        pushNotifications: push,
        emailNotifications: email,
        language: lang,
      );
    } catch (_) {}
  }

  Future<void> toggleDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDarkMode, value);
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
