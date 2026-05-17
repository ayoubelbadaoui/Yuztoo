import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/email_validator.dart';
import '../../../core/utils/oauth_profile_photo.dart';
import '../../discovery/application/providers.dart';
import '../application/providers.dart';
import '../infrastructure/merchant_city_resolution.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../merchant_onboarding/application/onboarding_flow_provider.dart';
import '../../merchant_onboarding/application/screens.dart';
import '../../merchant_onboarding/application/widgets.dart';
import '../../profile/application/providers.dart' show refreshUserProfileCache;

part 'merchant_profile_form_screen.part.dart';

/// Merchant profile – uses the 8-step onboarding flow (avatars, step-by-step).
/// Shown when merchant has no profile yet (after signup or when opening app).
class MerchantProfileFormScreen extends ConsumerStatefulWidget {
  const MerchantProfileFormScreen({
    super.key,
    this.onBack,
    this.onComplete,
    this.skipPersonalInfo = false,
  });

  final VoidCallback? onBack;
  final VoidCallback? onComplete;

  /// When true (client upgrading to merchant), personal steps — owner name,
  /// DOB, and logo — are skipped since that data already exists on the account.
  final bool skipPersonalInfo;

  @override
  ConsumerState<MerchantProfileFormScreen> createState() =>
      _MerchantProfileFormScreenState();
}

class _MerchantProfileFormScreenState
    extends ConsumerState<MerchantProfileFormScreen> {
  bool _didInit = false;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefillOnboardingFromCache();
    });
  }

  Future<void> _prefillOnboardingFromCache() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    final cacheService = ref.read(merchantProfileCacheServiceProvider);
    final cachedData = await cacheService.loadProfile();

    if (!mounted) return;
    final notifier = ref.read(onboardingFlowProvider.notifier);

    if (cachedData['userId'] == userId) {
      if (cachedData['name'] != null) notifier.setFullName(cachedData['name']!);
      if (cachedData['address'] != null) notifier.setAddress(cachedData['address']!);
      if (cachedData['category'] != null) {
        notifier.setCategory(cachedData['category']!, cachedData['category']!);
      }
      if (cachedData['description'] != null) {
        notifier.setDescription(cachedData['description']!);
      }
      if (cachedData['phone'] != null) {
        notifier.setPhoneNumber(cachedData['phone']!);
      }
      if (cachedData['websiteUrl'] != null) {
        notifier.setWebsiteUrl(cachedData['websiteUrl']!);
      }
    }

    // For a client upgrading to merchant, personal info (name, DOB, city)
    // already exists on the user profile — pre-fill silently so the
    // skipped steps still land in onboarding state for the final save.
    if (widget.skipPersonalInfo) {
      final basicsResult =
          await ref.read(auth_providers.getUserProfileBasicsProvider).call(userId);
      if (!mounted) return;
      final basics = basicsResult.fold((_) => null, (b) => b);
      if (basics != null) {
        if (basics.firstName?.isNotEmpty == true) {
          notifier.setOwnerFirstName(basics.firstName!);
        }
        if (basics.lastName?.isNotEmpty == true) {
          notifier.setOwnerLastName(basics.lastName!);
        }
        if (basics.dateOfBirth != null) {
          notifier.setOwnerDateOfBirth(basics.dateOfBirth);
        }
        if (basics.city.isNotEmpty) {
          notifier.setCity(basics.city);
        }
      }
    }

    // Seed commerce logo from Google / Apple profile photo when available.
    final oauthUrl = authState.user.photoUrl?.trim();
    final existingLogo = ref.read(onboardingFlowProvider).imagePath?.trim();
    if ((existingLogo == null || existingLogo.isEmpty) &&
        isUsableOAuthProfilePhotoUrl(oauthUrl)) {
      final path = await downloadOAuthProfilePhotoToTempFile(oauthUrl!);
      if (path != null && mounted) {
        notifier.setImagePath(path);
      }
    }
  }

  void _setSubmitting(bool value) {
    if (!mounted) return;
    setState(() => _isSubmitting = value);
  }

  @override
  Widget build(BuildContext context) {
    return MerchantOnboardingFlowScreen(
      isPostSignup: true,
      skipPersonalInfo: widget.skipPersonalInfo,
      onBack: widget.onBack ?? () {},
      onComplete: () {},
      onPostSignupPersist: _saveFromOnboarding,
    );
  }
}
