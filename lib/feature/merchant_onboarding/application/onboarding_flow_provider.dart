import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/logger_service.dart';

/// Collected data during merchant onboarding (before signup).
/// Used to prefill merchant profile form after signup.
class MerchantOnboardingData {
  const MerchantOnboardingData({
    this.ownerFirstName,
    this.ownerLastName,
    this.ownerDateOfBirth,
    this.fullName,
    this.city,
    this.imagePath,
    this.bannerImagePath,
    this.address,
    this.phoneNumber,
    this.contactEmail,
    this.websiteUrl,
    this.categoryId,
    this.categoryTitle,
    this.subcategoryTitle,
    this.description,
    this.hoursJson,
    this.merchantType,
  });

  /// Owner's personal identity — stored in users/{uid}.
  final String? ownerFirstName;
  final String? ownerLastName;
  final DateTime? ownerDateOfBirth;

  final String? fullName;
  final String? city;
  final String? imagePath;
  final String? bannerImagePath;
  final String? address;
  final String? phoneNumber;

  /// Public contact email shown on the merchant's storefront. Distinct from
  /// the Firebase Auth login email — a merchant may want to log in with
  /// `patron@gmail.com` but display `contact@boulangerie.fr` to clients.
  /// Defaults to the auth email at the start of onboarding; the merchant
  /// may overwrite it on the address step.
  final String? contactEmail;

  final String? websiteUrl;
  final String? categoryId;
  final String? categoryTitle;
  final String? subcategoryTitle;
  final String? description;
  final Map<String, dynamic>? hoursJson;

  /// 'b2b' or 'b2c'. Persisted to `merchants/{id}.merchant_type` on
  /// submit. Drives the sphere filter on the Recommandations screen and
  /// — later — a Découvrir filter for end-users. Null until the
  /// merchant picks; the wizard step gates Suivant until they do, so
  /// this never lands as null in the final write.
  final String? merchantType;

  MerchantOnboardingData copyWith({
    String? ownerFirstName,
    String? ownerLastName,
    DateTime? ownerDateOfBirth,
    String? fullName,
    String? city,
    String? imagePath,
    String? bannerImagePath,
    String? address,
    String? phoneNumber,
    String? contactEmail,
    String? websiteUrl,
    String? categoryId,
    String? categoryTitle,
    String? subcategoryTitle,
    String? description,
    Map<String, dynamic>? hoursJson,
    String? merchantType,
  }) {
    return MerchantOnboardingData(
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      ownerLastName: ownerLastName ?? this.ownerLastName,
      ownerDateOfBirth: ownerDateOfBirth ?? this.ownerDateOfBirth,
      fullName: fullName ?? this.fullName,
      city: city ?? this.city,
      imagePath: imagePath ?? this.imagePath,
      bannerImagePath: bannerImagePath ?? this.bannerImagePath,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactEmail: contactEmail ?? this.contactEmail,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      subcategoryTitle: subcategoryTitle ?? this.subcategoryTitle,
      description: description ?? this.description,
      hoursJson: hoursJson ?? this.hoursJson,
      merchantType: merchantType ?? this.merchantType,
    );
  }
}

class OnboardingFlowNotifier extends StateNotifier<MerchantOnboardingData> {
  OnboardingFlowNotifier() : super(const MerchantOnboardingData());

  void setOwnerFirstName(String value) => state =
      state.copyWith(ownerFirstName: value.trim().isEmpty ? null : value.trim());

  void setOwnerLastName(String value) => state =
      state.copyWith(ownerLastName: value.trim().isEmpty ? null : value.trim());

  void setOwnerDateOfBirth(DateTime? date) =>
      state = state.copyWith(ownerDateOfBirth: date);

  void setFullName(String value) =>
      state = state.copyWith(fullName: value.trim().isEmpty ? null : value.trim());

  void setCity(String value) =>
      state = state.copyWith(city: value.trim().isEmpty ? null : value.trim());

  void setImagePath(String? path) => state = state.copyWith(imagePath: path);

  void setBannerImagePath(String? path) =>
      state = state.copyWith(bannerImagePath: path);

  void setAddress(String value) =>
      state = state.copyWith(address: value.trim().isEmpty ? null : value.trim());

  void setPhoneNumber(String value) => state =
      state.copyWith(phoneNumber: value.trim().isEmpty ? null : value.trim());

  /// Lower-cases the contact email before persisting — Firebase Auth and
  /// the email_index collection both store emails in lowercase, so we
  /// normalise here to keep storefront display consistent with auth.
  void setContactEmail(String value) {
    final trimmed = value.trim();
    state = state.copyWith(
      contactEmail: trimmed.isEmpty ? null : trimmed.toLowerCase(),
    );
  }

  void setWebsiteUrl(String value) => state =
      state.copyWith(websiteUrl: value.trim().isEmpty ? null : value.trim());

  void setCategory(String id, String title) {
    LoggerService.logInfo(
      'Onboarding category selected',
      context: <String, dynamic>{
        'categoryId': id,
        'categoryTitle': title,
        'merchantType': state.merchantType,
        'previousCategoryId': state.categoryId,
        'previousCategoryTitle': state.categoryTitle,
      },
    );
    state = state.copyWith(categoryId: id, categoryTitle: title);
  }

  void setSubcategoryTitle(String title) {
    LoggerService.logInfo(
      'Onboarding subcategory selected',
      context: <String, dynamic>{
        'subcategoryTitle': title,
        'categoryId': state.categoryId,
        'categoryTitle': state.categoryTitle,
        'merchantType': state.merchantType,
        'previousSubcategoryTitle': state.subcategoryTitle,
      },
    );
    state = state.copyWith(subcategoryTitle: title);
  }

  void setDescription(String? value) =>
      state = state.copyWith(description: value?.trim().isEmpty == true ? null : value?.trim());

  void setHours(Map<String, dynamic>? hours) =>
      state = state.copyWith(hoursJson: hours);

  /// Defensive: only accept the wire values the schema knows about.
  /// A bad value from a future caller is dropped (no-op) rather than
  /// poisoning the state and cascading into a bad Firestore write.
  void setMerchantType(String value) {
    if (value != 'b2b' && value != 'b2c') return;
    LoggerService.logInfo(
      'Onboarding merchant type selected',
      context: <String, dynamic>{
        'merchantType': value,
        'previousMerchantType': state.merchantType,
      },
    );
    state = state.copyWith(merchantType: value);
  }

  void reset() => state = const MerchantOnboardingData();
}

final onboardingFlowProvider =
    StateNotifierProvider<OnboardingFlowNotifier, MerchantOnboardingData>(
        (ref) => OnboardingFlowNotifier());
