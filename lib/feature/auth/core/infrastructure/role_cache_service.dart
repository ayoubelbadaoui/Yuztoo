import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../types.dart';

/// Service for caching user's last selected role
/// Used for multi-role users to remember their preference
class RoleCacheService {
  static const String _keyLastSelectedRole = 'last_selected_role';

  /// Get the last selected role from cache
  /// Returns null if no role is cached
  Future<UserRole?> getLastSelectedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleString = prefs.getString(_keyLastSelectedRole);
      if (roleString == null) return null;
      
      return roleString == 'client' ? UserRole.client : UserRole.merchant;
    } catch (e) {
      // If error, return null (no cached role)
      return null;
    }
  }

  /// Save the selected role to cache
  Future<void> saveLastSelectedRole(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyLastSelectedRole,
        role == UserRole.client ? 'client' : 'merchant',
      );
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Clear the cached role
  Future<void> clearLastSelectedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastSelectedRole);
    } catch (e) {
      // Silently fail
    }
  }
}

