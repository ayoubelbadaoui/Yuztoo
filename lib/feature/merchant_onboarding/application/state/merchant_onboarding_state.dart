import 'package:equatable/equatable.dart';

/// Immutable state class for merchant onboarding wizard.
/// 
/// Stores the selected category and subcategory during the onboarding flow.
/// This state is used to persist selections across wizard screens and
/// is used when creating the merchant document after signup.
class MerchantOnboardingState extends Equatable {
  const MerchantOnboardingState({
    this.selectedCategoryId,
    this.selectedSubcategoryId,
  });

  /// Selected category ID (e.g., 'restaurant', 'retail', 'beauty')
  final String? selectedCategoryId;

  /// Selected subcategory ID (e.g., 'restaurant_french', 'restaurant_italian')
  /// Only applicable for certain categories like restaurant
  final String? selectedSubcategoryId;

  /// Whether the wizard is complete (both category and subcategory selected if needed)
  bool get isComplete {
    // For now, category is required, subcategory is optional
    // Can be extended later if subcategory becomes required for certain categories
    return selectedCategoryId != null && selectedCategoryId!.isNotEmpty;
  }

  /// Create a copy with updated fields
  MerchantOnboardingState copyWith({
    String? selectedCategoryId,
    String? selectedSubcategoryId,
    bool? clearCategory,
    bool? clearSubcategory,
  }) {
    return MerchantOnboardingState(
      selectedCategoryId: clearCategory == true
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedSubcategoryId: clearSubcategory == true
          ? null
          : (selectedSubcategoryId ?? this.selectedSubcategoryId),
    );
  }

  /// Reset state to initial (empty)
  MerchantOnboardingState reset() {
    return const MerchantOnboardingState();
  }

  @override
  List<Object?> get props => [selectedCategoryId, selectedSubcategoryId];

  @override
  String toString() {
    return 'MerchantOnboardingState('
        'categoryId: $selectedCategoryId, '
        'subcategoryId: $selectedSubcategoryId, '
        'isComplete: $isComplete'
        ')';
  }
}

