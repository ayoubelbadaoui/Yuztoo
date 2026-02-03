import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/merchant_onboarding_state.dart';
import '../../infrastructure/onboarding_storage.dart';

/// Controller for managing merchant onboarding wizard state.
/// 
/// This controller manages the selected category and subcategory
/// during the merchant onboarding flow. The state persists across
/// wizard screens and is used when creating the merchant document.
/// 
/// FIX HIGH 4: State persistence - state is saved to SharedPreferences
/// so users can resume onboarding if app is closed.
class MerchantOnboardingController extends StateNotifier<MerchantOnboardingState> {
  MerchantOnboardingController(this._storage) : super(const MerchantOnboardingState()) {
    // Load persisted state on initialization
    _loadPersistedState();
  }

  final OnboardingStorage? _storage;

  /// Load persisted state from storage.
  void _loadPersistedState() {
    if (_storage == null) return;
    
    final categoryId = _storage.loadCategoryId();
    final subcategoryId = _storage.loadSubcategoryId();
    
    if (categoryId != null || subcategoryId != null) {
      state = MerchantOnboardingState(
        selectedCategoryId: categoryId,
        selectedSubcategoryId: subcategoryId,
      );
    }
  }

  /// Select a category in the onboarding wizard.
  /// 
  /// [categoryId] - The ID of the selected category (e.g., 'restaurant', 'retail')
  void selectCategory(String categoryId) {
    if (categoryId.isEmpty) {
      return;
    }
    state = state.copyWith(selectedCategoryId: categoryId);
    // FIX HIGH 4: Persist state to storage
    _storage?.saveCategoryId(categoryId);
  }

  /// Select a subcategory in the onboarding wizard.
  /// 
  /// [subcategoryId] - The ID of the selected subcategory (e.g., 'restaurant_french')
  void selectSubcategory(String subcategoryId) {
    if (subcategoryId.isEmpty) {
      return;
    }
    state = state.copyWith(selectedSubcategoryId: subcategoryId);
    // FIX HIGH 4: Persist state to storage
    _storage?.saveSubcategoryId(subcategoryId);
  }

  /// Clear the selected category.
  void clearCategory() {
    state = state.copyWith(clearCategory: true);
    // FIX HIGH 4: Clear persisted state
    _storage?.saveCategoryId(null);
  }

  /// Clear the selected subcategory.
  void clearSubcategory() {
    state = state.copyWith(clearSubcategory: true);
    // FIX HIGH 4: Clear persisted state
    _storage?.saveSubcategoryId(null);
  }

  /// Reset the onboarding state to initial (empty).
  /// 
  /// This clears both category and subcategory selections.
  void reset() {
    state = state.reset();
    // FIX HIGH 4: Clear all persisted state
    _storage?.clear();
  }

  /// Get the current selected category ID.
  String? get selectedCategoryId => state.selectedCategoryId;

  /// Get the current selected subcategory ID.
  String? get selectedSubcategoryId => state.selectedSubcategoryId;

  /// Check if the onboarding wizard is complete.
  bool get isComplete => state.isComplete;
}

