import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persisting merchant onboarding state.
/// 
/// FIX HIGH 4: State persistence for onboarding
/// This allows users to resume onboarding if app is closed.
class OnboardingStorage {
  OnboardingStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyCategoryId = 'merchant_onboarding_category_id';
  static const String _keySubcategoryId = 'merchant_onboarding_subcategory_id';

  /// Save category ID to persistent storage.
  Future<void> saveCategoryId(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) {
      await _prefs.remove(_keyCategoryId);
    } else {
      await _prefs.setString(_keyCategoryId, categoryId);
    }
  }

  /// Save subcategory ID to persistent storage.
  Future<void> saveSubcategoryId(String? subcategoryId) async {
    if (subcategoryId == null || subcategoryId.isEmpty) {
      await _prefs.remove(_keySubcategoryId);
    } else {
      await _prefs.setString(_keySubcategoryId, subcategoryId);
    }
  }

  /// Load category ID from persistent storage.
  String? loadCategoryId() {
    return _prefs.getString(_keyCategoryId);
  }

  /// Load subcategory ID from persistent storage.
  String? loadSubcategoryId() {
    return _prefs.getString(_keySubcategoryId);
  }

  /// Clear all onboarding state from storage.
  Future<void> clear() async {
    await _prefs.remove(_keyCategoryId);
    await _prefs.remove(_keySubcategoryId);
  }
}

