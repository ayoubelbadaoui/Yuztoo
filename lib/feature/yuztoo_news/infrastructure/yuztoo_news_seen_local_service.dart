import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which actu the user already opened, so the gold "new" dot
/// disappears once read. Local on purpose: the actu is global content, there
/// is nothing worth storing server-side per user.
///
/// Best-effort: a corrupted preferences file must only cost the dot.
class YuztooNewsSeenLocalService {
  static String _keyFor(String userId) =>
      'client.yuztoo_news_seen.${userId.isEmpty ? 'guest' : userId}';

  Future<String?> readSeenId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyFor(userId));
    } catch (_) {
      return null;
    }
  }

  Future<void> markSeen(String userId, String newsId) async {
    if (newsId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(userId), newsId);
    } catch (_) {}
  }
}
