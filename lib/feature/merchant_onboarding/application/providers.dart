import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/merchant_onboarding_controller.dart';
import 'state/merchant_onboarding_state.dart';
import '../infrastructure/onboarding_storage.dart';

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

/// Provider for OnboardingStorage.
final onboardingStorageProvider = Provider<OnboardingStorage?>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => OnboardingStorage(prefs),
    loading: () => null, // Return null while loading
    error: (_, __) => null, // Return null on error (graceful degradation)
  );
});

/// Provider for MerchantOnboardingController with state persistence.
/// 
/// FIX HIGH 4: State persistence - controller loads and saves state to SharedPreferences.
final merchantOnboardingControllerProvider =
    StateNotifierProvider<MerchantOnboardingController, MerchantOnboardingState>(
  (ref) {
    final storage = ref.watch(onboardingStorageProvider);
    return MerchantOnboardingController(storage);
  },
);

