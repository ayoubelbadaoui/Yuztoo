import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/personal_profile_image_cache.dart';

class SharedPreferencesPersonalProfileImageCache
    implements PersonalProfileImageCache {
  static const _keyPrefix = 'user_personal_profile_image_';

  @override
  Future<String?> getCachedImagePath(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$userId');
  }

  @override
  Future<void> saveCachedImagePath(String userId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$userId', path);
  }
}
