import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/city_input.dart';
import '../../../../types.dart';

/// Persists lightweight auth/navigation hints locally.
///
/// This is intentionally a small, best-effort cache so the app can still route
/// correctly when Firestore is temporarily unavailable (e.g. PERMISSION_DENIED
/// due to misconfigured rules on a dev project).
class RoleCacheService {
  static const _keyLastSelectedRole = 'auth.last_selected_role';
  static const _keyForceMerchantNextLogin = 'auth.force_merchant_next_login';
  static const _keyPendingSignupCityUid = 'auth.pending_signup_city_uid';
  static const _keyPendingSignupCity = 'auth.pending_signup_city';

  static String _roleKeyForUser(String userId) =>
      'auth.last_selected_role.$userId';

  static UserRole? _parseRole(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'merchant' => UserRole.merchant,
      'client' => UserRole.client,
      _ => null,
    };
  }

  /// Persists the last client vs merchant shell the user was in.
  ///
  /// When [userId] is set, storage is scoped per account so another login
  /// on the same device does not inherit the previous user's session.
  Future<void> saveLastSelectedRole(UserRole role, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_roleKeyForUser(userId), role.name);
    }
    await prefs.setString(_keyLastSelectedRole, role.name);
  }

  Future<UserRole?> readLastSelectedRole({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      final perUser = _parseRole(prefs.getString(_roleKeyForUser(userId)));
      if (perUser != null) return perUser;
    }
    return _parseRole(prefs.getString(_keyLastSelectedRole));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastSelectedRole);
    await prefs.remove(_keyForceMerchantNextLogin);
    await prefs.remove(_keyPendingSignupCityUid);
    await prefs.remove(_keyPendingSignupCity);
  }

  /// Call after Firestore `users/{uid}` is written at signup so merchant onboarding
  /// can read the inscription city even if a later `/users` read fails or lags.
  Future<void> savePendingSignupCity({
    required String uid,
    required String city,
  }) async {
    final persisted = CityInput.forFirestore(city);
    if (persisted == null || uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingSignupCityUid, uid);
    await prefs.setString(_keyPendingSignupCity, persisted);
  }

  /// Non-destructive read; same value until [clearPendingSignupCity] or [clear].
  Future<String?> peekPendingSignupCity({required String uid}) async {
    if (uid.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final storedUid = prefs.getString(_keyPendingSignupCityUid);
    final raw = prefs.getString(_keyPendingSignupCity);
    if (storedUid != uid || raw == null || raw.isEmpty) return null;
    if (CityInput.isPlaceholder(raw)) return null;
    return raw.trim();
  }

  Future<void> clearPendingSignupCity({required String uid}) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final storedUid = prefs.getString(_keyPendingSignupCityUid);
    if (storedUid != uid) return;
    await prefs.remove(_keyPendingSignupCityUid);
    await prefs.remove(_keyPendingSignupCity);
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



