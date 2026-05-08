import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/city_input.dart';
import '../../../../core/infrastructure/firebase_providers.dart';
import '../domain/entities/storefront.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';

part 'profile_edit_state.part.dart';

class StorefrontProfileEditState {
  const StorefrontProfileEditState({
    required this.bannerImageUrl,
    required this.profileImageUrl,
    required this.businessName,
    required this.category,
    required this.description,
    required this.phoneNumber,
    required this.email,
    required this.websiteUrl,
    required this.address,
    required this.city,
    required this.welcomeGiftDescription,
    this.merchantType = 'b2c',
    this.isSaving = false,
    this.errorMessage,
  });

  final String bannerImageUrl;
  final String profileImageUrl;
  final String businessName;
  final String category;
  final String description;
  final String phoneNumber;
  final String email;
  final String websiteUrl;
  final String address;
  final String city;
  final String welcomeGiftDescription;

  /// 'b2b' or 'b2c'. Persisted to merchants/{id}.merchant_type and read
  /// by the Recommandations screen filter. Default 'b2c' covers both
  /// new merchants who skipped the wizard step (shouldn't happen
  /// post-this commit) and legacy docs without the field.
  final String merchantType;

  final bool isSaving;
  final String? errorMessage;

  StorefrontProfileEditState copyWith({
    String? bannerImageUrl,
    String? profileImageUrl,
    String? businessName,
    String? category,
    String? description,
    String? phoneNumber,
    String? email,
    String? websiteUrl,
    String? address,
    String? city,
    String? welcomeGiftDescription,
    String? merchantType,
    bool? isSaving,
    String? errorMessage,
  }) {
    return StorefrontProfileEditState(
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      welcomeGiftDescription:
          welcomeGiftDescription ?? this.welcomeGiftDescription,
      merchantType: merchantType ?? this.merchantType,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

final storefrontProfileEditProvider = StateNotifierProvider<
    StorefrontProfileEditNotifier,
    StorefrontProfileEditState>((ref) {
  return StorefrontProfileEditNotifier(ref);
});
