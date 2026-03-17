import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for merchant profile data (demo mode).
/// 
/// Saves merchant profile to local storage so the form works even when
/// Firestore is unavailable (e.g., permission-denied during demo).
class MerchantProfileCacheService {
  static const _keyPrefix = 'merchant_profile_cache.';
  static const _keyName = '${_keyPrefix}name';
  static const _keyEmail = '${_keyPrefix}email';
  static const _keyPhone = '${_keyPrefix}phone';
  static const _keyCity = '${_keyPrefix}city';
  static const _keyAddress = '${_keyPrefix}address';
  static const _keyCategory = '${_keyPrefix}category';
  static const _keyDescription = '${_keyPrefix}description';
  static const _keyBannerImagePath = '${_keyPrefix}banner_image_path';
  static const _keyProfileImagePath = '${_keyPrefix}profile_image_path';
  static const _keyWebsiteUrl = '${_keyPrefix}website_url';
  static const _keyUserId = '${_keyPrefix}user_id';

  /// Save merchant profile data to local cache
  Future<void> saveProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String city,
    String? address,
    String? category,
    String? description,
    String? bannerImagePath,
    String? profileImagePath,
    String? websiteUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyUserId, userId),
      prefs.setString(_keyName, name),
      prefs.setString(_keyEmail, email),
      prefs.setString(_keyPhone, phone),
      prefs.setString(_keyCity, city),
      if (address != null && address.trim().isNotEmpty) prefs.setString(_keyAddress, address.trim()) else prefs.remove(_keyAddress),
      if (category != null && category.trim().isNotEmpty) prefs.setString(_keyCategory, category.trim()) else prefs.remove(_keyCategory),
      if (description != null && description.trim().isNotEmpty) prefs.setString(_keyDescription, description.trim()) else prefs.remove(_keyDescription),
      if (bannerImagePath != null && bannerImagePath.trim().isNotEmpty) prefs.setString(_keyBannerImagePath, bannerImagePath.trim()) else prefs.remove(_keyBannerImagePath),
      if (profileImagePath != null && profileImagePath.trim().isNotEmpty) prefs.setString(_keyProfileImagePath, profileImagePath.trim()) else prefs.remove(_keyProfileImagePath),
      if (websiteUrl != null && websiteUrl.trim().isNotEmpty) prefs.setString(_keyWebsiteUrl, websiteUrl.trim()) else prefs.remove(_keyWebsiteUrl),
    ]);
  }

  /// Load merchant profile data from local cache
  Future<Map<String, String?>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'name': prefs.getString(_keyName),
      'email': prefs.getString(_keyEmail),
      'phone': prefs.getString(_keyPhone),
      'city': prefs.getString(_keyCity),
      'address': prefs.getString(_keyAddress),
      'category': prefs.getString(_keyCategory),
      'description': prefs.getString(_keyDescription),
      'bannerImagePath': prefs.getString(_keyBannerImagePath),
      'profileImagePath': prefs.getString(_keyProfileImagePath),
      'websiteUrl': prefs.getString(_keyWebsiteUrl),
    };
  }

  /// Check if cached profile exists for a user
  Future<bool> hasCachedProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUserId = prefs.getString(_keyUserId);
    return cachedUserId == userId && prefs.getString(_keyEmail) != null;
  }

  /// Clear cached profile data
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyUserId),
      prefs.remove(_keyName),
      prefs.remove(_keyEmail),
      prefs.remove(_keyPhone),
      prefs.remove(_keyCity),
      prefs.remove(_keyAddress),
      prefs.remove(_keyCategory),
      prefs.remove(_keyDescription),
      prefs.remove(_keyBannerImagePath),
      prefs.remove(_keyProfileImagePath),
      prefs.remove(_keyWebsiteUrl),
    ]);
  }
}

