import 'package:shared_preferences/shared_preferences.dart';

class ViewedMerchantsLocalService {
  static String _keyFor(String userId) => 'client.viewed_merchants.$userId';

  Future<Set<String>> readViewedIds(String userId) async {
    if (userId.isEmpty) return <String>{};
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_keyFor(userId)) ?? const <String>[];
    return values.toSet();
  }

  Future<void> markViewed(String userId, String merchantId) async {
    if (userId.isEmpty || merchantId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(userId);
    final values = (prefs.getStringList(key) ?? const <String>[]).toSet();
    values.add(merchantId);
    await prefs.setStringList(key, values.toList());
  }
}
