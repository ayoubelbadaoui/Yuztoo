import 'package:shared_preferences/shared_preferences.dart';

import '../../../../types.dart';

/// Persists lightweight auth/navigation hints locally.
///
/// This is intentionally a small, best-effort cache so the app can still route
/// correctly when Firestore is temporarily unavailable (e.g. PERMISSION_DENIED
/// due to misconfigured rules on a dev project).
class RoleCacheService {
  static const _keyLastSelectedRole = 'auth.last_selected_role';

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
  }
}



