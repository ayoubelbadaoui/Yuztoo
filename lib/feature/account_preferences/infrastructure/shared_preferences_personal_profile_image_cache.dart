import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/personal_profile_image_cache.dart';

/// Best-effort: a corrupted preferences file reads as "nothing cached".
class SharedPreferencesPersonalProfileImageCache
    implements PersonalProfileImageCache {
  static const _keyPrefix = 'user_personal_profile_image_';

  @override
  Future<String?> getCachedImagePath(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_keyPrefix$userId');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCachedImagePath(String userId, String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$userId', path);
    } catch (_) {}
  }
}
