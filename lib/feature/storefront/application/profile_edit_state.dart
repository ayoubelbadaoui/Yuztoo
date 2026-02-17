import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/storefront.dart';

class StorefrontProfileEditState {
  const StorefrontProfileEditState({
    required this.bannerImageUrl,
    required this.profileImageUrl,
    required this.businessName,
    required this.category,
    required this.description,
    required this.phoneNumber,
    required this.websiteUrl,
    required this.address,
    this.isSaving = false,
  });

  final String bannerImageUrl;
  final String profileImageUrl;
  final String businessName;
  final String category;
  final String description;
  final String phoneNumber;
  final String websiteUrl;
  final String address;
  final bool isSaving;

  StorefrontProfileEditState copyWith({
    String? bannerImageUrl,
    String? profileImageUrl,
    String? businessName,
    String? category,
    String? description,
    String? phoneNumber,
    String? websiteUrl,
    String? address,
    bool? isSaving,
  }) {
    return StorefrontProfileEditState(
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      address: address ?? this.address,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class StorefrontProfileEditNotifier
    extends StateNotifier<StorefrontProfileEditState> {
  StorefrontProfileEditNotifier()
      : super(
          const StorefrontProfileEditState(
            bannerImageUrl: '',
            profileImageUrl: '',
            businessName: '',
            category: '',
            description: '',
            phoneNumber: '',
            websiteUrl: '',
            address: '',
          ),
        );

  void initializeFrom(Storefront storefront) {
    state = state.copyWith(
      bannerImageUrl: storefront.bannerImageUrl,
      profileImageUrl: storefront.profileImageUrl,
      businessName: storefront.merchantName,
      // storefront entity doesn't contain these yet → sensible defaults
      category: state.category.isEmpty ? 'Artisan Jewelry' : state.category,
      description: state.description.isEmpty
          ? 'Décrivez votre activité en quelques lignes.'
          : state.description,
      phoneNumber: state.phoneNumber.isEmpty ? '+33 6 12 34 56 78' : state.phoneNumber,
      websiteUrl: state.websiteUrl.isEmpty ? 'www.votresite.com' : state.websiteUrl,
      address: state.address.isEmpty ? 'Votre adresse' : state.address,
    );
  }

  void setBusinessName(String v) => state = state.copyWith(businessName: v);
  void setCategory(String v) => state = state.copyWith(category: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setPhoneNumber(String v) => state = state.copyWith(phoneNumber: v);
  void setWebsiteUrl(String v) => state = state.copyWith(websiteUrl: v);
  void setAddress(String v) => state = state.copyWith(address: v);

  void setBannerImageUrl(String v) => state = state.copyWith(bannerImageUrl: v);
  void setProfileImageUrl(String v) => state = state.copyWith(profileImageUrl: v);

  Future<void> save() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true);
    // TODO(infra): persist to repository / backend
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isSaving: false);
  }
}

final storefrontProfileEditProvider = StateNotifierProvider<
    StorefrontProfileEditNotifier,
    StorefrontProfileEditState>((ref) {
  return StorefrontProfileEditNotifier();
});


