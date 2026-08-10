import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kOnboardingCompletedKey = 'onboarding_completed';

/// AsyncNotifier that properly awaits SharedPreferences before resolving.
/// This ensures the splash screen never reads a stale `false` initial value.
class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardingCompletedKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingCompletedKey, true);
    state = const AsyncValue.data(true);
  }
}

final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);
