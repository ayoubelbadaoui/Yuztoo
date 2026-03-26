import 'package:shared_preferences/shared_preferences.dart';

import '../../../../types.dart';

/// Persists lightweight auth/navigation hints locally.
///
/// This is intentionally a small, best-effort cache so the app can still route
/// correctly when Firestore is temporarily unavailable (e.g. PERMISSION_DENIED
/// due to misconfigured rules on a dev project).
class RoleCacheService {
  static const _keyLastSelectedRole = 'auth.last_selected_role';
  static const _keyForceMerchantNextLogin = 'auth.force_merchant_next_login';

  Future<void> saveLastSelectedRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSelectedRole, role.name);
  }

  Future<UserRole?> readLastSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastSelectedRole);
    if (raw == null || raw.isEmpty) return null;

    return switch (raw) {
      'merchant' => UserRole.merchant,
      'client' => UserRole.client,
      _ => null,
    };
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastSelectedRole);
    await prefs.remove(_keyForceMerchantNextLogin);
  }

  /// Sets a one-time hint to open merchant view on the next authenticated route.
  Future<void> setForceMerchantNextLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyForceMerchantNextLogin, value);
  }

  /// Returns and clears the one-time merchant hint.
  Future<bool> consumeForceMerchantNextLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyForceMerchantNextLogin) ?? false;
    if (enabled) {
      await prefs.remove(_keyForceMerchantNextLogin);
    }
    return enabled;
  }
}



