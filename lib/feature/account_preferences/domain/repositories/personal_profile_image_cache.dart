/// Local cache for the client's personal profile photo path (not merchant assets).
abstract class PersonalProfileImageCache {
  Future<String?> getCachedImagePath(String userId);

  Future<void> saveCachedImagePath(String userId, String path);
}
