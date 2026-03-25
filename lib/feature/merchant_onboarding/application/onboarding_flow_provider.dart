import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Collected data during merchant onboarding (before signup).
/// Used to prefill merchant profile form after signup.
class MerchantOnboardingData {
  const MerchantOnboardingData({
    this.fullName,
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

  final String? fullName;
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
    String? fullName,
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
      fullName: fullName ?? this.fullName,
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

  void setFullName(String value) =>
      state = state.copyWith(fullName: value.trim().isEmpty ? null : value.trim());

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
