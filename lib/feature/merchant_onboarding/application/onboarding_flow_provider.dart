import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.websiteUrl,
    this.categoryId,
    this.categoryTitle,
    this.description,
    this.hoursJson,
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
  final String? websiteUrl;
  final String? categoryId;
  final String? categoryTitle;
  final String? description;
  final Map<String, dynamic>? hoursJson;

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
    String? websiteUrl,
    String? categoryId,
    String? categoryTitle,
    String? description,
    Map<String, dynamic>? hoursJson,
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
      websiteUrl: websiteUrl ?? this.websiteUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      description: description ?? this.description,
      hoursJson: hoursJson ?? this.hoursJson,
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

  void setWebsiteUrl(String value) => state =
      state.copyWith(websiteUrl: value.trim().isEmpty ? null : value.trim());

  void setCategory(String id, String title) =>
      state = state.copyWith(categoryId: id, categoryTitle: title);

  void setDescription(String? value) =>
      state = state.copyWith(description: value?.trim().isEmpty == true ? null : value?.trim());

  void setHours(Map<String, dynamic>? hours) =>
      state = state.copyWith(hoursJson: hours);

  void reset() => state = const MerchantOnboardingData();
}

final onboardingFlowProvider =
    StateNotifierProvider<OnboardingFlowNotifier, MerchantOnboardingData>(
        (ref) => OnboardingFlowNotifier());
