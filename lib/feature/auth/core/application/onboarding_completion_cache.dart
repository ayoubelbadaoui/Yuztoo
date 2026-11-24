import 'package:shared_preferences/shared_preferences.dart';

/// Per-device memory of « this account already finished onboarding ».
///
/// Startup routing reads `users/{uid}.onboarding` from Firestore. When that
/// read fails or stalls (offline, flaky network, just-reinstalled app with an
/// empty cache), the shell used to route straight into onboarding — so a
/// client saw « Bienvenue » again, and a merchant could re-run the wizard and
/// overwrite their shop. A definitive Firestore answer always wins; this is
/// only consulted when Firestore gave no answer.
class OnboardingCompletionCache {
  const OnboardingCompletionCache._();

  static String _key(String role, String uid) => 'onboarding_done_${role}_$uid';

  static Future<bool> wasCompleted(String role, String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(role, uid)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markCompleted(String role, String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(role, uid), true);
    } catch (_) {}
  }
}
