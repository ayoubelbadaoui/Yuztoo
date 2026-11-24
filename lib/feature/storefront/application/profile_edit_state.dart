import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/entities/french_commune.dart';
import '../../../../core/infrastructure/firebase_providers.dart';
import '../../../../core/utils/city_input.dart';
import '../../../../core/utils/email_validator.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../domain/entities/storefront.dart';
import '../../../../core/utils/profile_placeholders.dart';
import '../../discovery/application/providers.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/domain/entities/mobility_accessibility.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../profile/application/refresh_user_profile_cache.dart';
import '../../merchant_onboarding/domain/entities/merchant_audience.dart';
import '../../merchant_onboarding/presentation/widgets/merchant_category_catalog.dart';
import '../../merchant_onboarding/presentation/widgets/subcategory/merchant_subcategory_catalog.dart';

part 'profile_edit_state.part.dart';

class StorefrontProfileEditState {
  const StorefrontProfileEditState({
    required this.bannerImageUrl,
    required this.profileImageUrl,
    required this.businessName,
    required this.category,
    required this.categoryId,
    required this.categoryTitle,
    required this.subcategoryTitle,
    required this.description,
    required this.phoneNumber,
    required this.email,
    required this.websiteUrl,
    required this.address,
    required this.city,
    this.commune,
    required this.welcomeGiftDescription,
    this.merchantType = 'b2c',
    this.mobilityAccessibility = MobilityAccessibility.defaultValue,
    this.isSaving = false,
    this.isLoaded = false,
    this.errorMessage,
  });

  final String bannerImageUrl;
  final String profileImageUrl;
  final String businessName;

  /// Specialty used for completion % / local cache (subcategory or free-text).
  final String category;

  /// Onboarding main sector id (e.g. `bouche`, `autre`).
  final String categoryId;

  /// Onboarding main sector title (e.g. `Métiers de bouche`, `Autre`).
  final String categoryTitle;

  /// Specialty title, or free-text when [categoryId] is "Autre".
  final String subcategoryTitle;

  final String description;
  final String phoneNumber;
  final String email;
  final String websiteUrl;
  final String address;
  final String city;

  /// Official commune / EPCI metadata when the city was picked from the catalog.
  final FrenchCommune? commune;

  final String welcomeGiftDescription;

  /// 'b2b' or 'b2c'. Persisted to merchants/{id}.merchant_type and read
  /// by the Recommandations screen filter. Default 'b2c' covers both
  /// new merchants who skipped the wizard step (shouldn't happen
  /// post-this commit) and legacy docs without the field.
  final String merchantType;

  /// PMR accessibility declared for the vitrine.
  final MobilityAccessibility mobilityAccessibility;

  final bool isSaving;

  /// True once [StorefrontProfileEditNotifier.initializeFrom] filled the form
  /// from the merchant; until then empty fields mean "unknown", not "cleared".
  final bool isLoaded;
  final String? errorMessage;

  /// True when the main sector has no curated specialties — show a text field.
  bool get isOtherCategory =>
      MerchantCategoryCatalog.isOtherCategoryId(categoryId) ||
      (categoryId.isNotEmpty &&
          !MerchantSubcategoryCatalog.hasSubcategoriesFor(categoryId));

  /// Main category is set and specialty (dropdown or free text) is filled.
  bool get hasCompleteCategory =>
      categoryId.trim().isNotEmpty && subcategoryTitle.trim().isNotEmpty;

  StorefrontProfileEditState copyWith({
    String? bannerImageUrl,
    String? profileImageUrl,
    String? businessName,
    String? category,
    String? categoryId,
    String? categoryTitle,
    String? subcategoryTitle,
    String? description,
    String? phoneNumber,
    String? email,
    String? websiteUrl,
    String? address,
    String? city,
    FrenchCommune? commune,
    bool clearCommune = false,
    String? welcomeGiftDescription,
    String? merchantType,
    MobilityAccessibility? mobilityAccessibility,
    bool? isSaving,
    bool? isLoaded,
    String? errorMessage,
  }) {
    return StorefrontProfileEditState(
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      subcategoryTitle: subcategoryTitle ?? this.subcategoryTitle,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      commune: clearCommune ? null : (commune ?? this.commune),
      welcomeGiftDescription:
          welcomeGiftDescription ?? this.welcomeGiftDescription,
      merchantType: merchantType ?? this.merchantType,
      mobilityAccessibility:
          mobilityAccessibility ?? this.mobilityAccessibility,
      isSaving: isSaving ?? this.isSaving,
      isLoaded: isLoaded ?? this.isLoaded,
      errorMessage: errorMessage,
    );
  }
}

final storefrontProfileEditProvider = StateNotifierProvider<
    StorefrontProfileEditNotifier, StorefrontProfileEditState>((ref) {
  return StorefrontProfileEditNotifier(ref);
});
