import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../application/providers.dart';
import '../../storage/application/providers.dart' as storage_providers;
import '../../storage/infrastructure/storage_repository_provider.dart';
import '../../merchant_onboarding/application/onboarding_flow_provider.dart';
import '../../merchant_onboarding/presentation/onboarding_flow_screen.dart';
import '../../merchant_onboarding/presentation/widgets/merchant_onboarding_colors.dart';
import '../../../feature/storefront/application/providers.dart' as storefront_providers;

/// Merchant profile – uses the 8-step onboarding flow (avatars, step-by-step).
/// Shown when merchant has no profile yet (after signup or when opening app).
class MerchantProfileFormScreen extends ConsumerStatefulWidget {
  const MerchantProfileFormScreen({
    super.key,
    this.onBack,
    this.onComplete,
  });

  final VoidCallback? onBack;
  final VoidCallback? onComplete;

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

    if (cachedData['userId'] != userId) return;

    if (!mounted) return;
    final notifier = ref.read(onboardingFlowProvider.notifier);
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

  Future<void> _saveFromOnboarding() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final user = authState.user;
    final userId = user.id;
    final data = ref.read(onboardingFlowProvider);

    const defaultCommerceName = 'Mon commerce';
    const defaultCityPlaceholder = 'À compléter';

    final trimmedName = data.fullName?.trim();
    final name = (trimmedName == null || trimmedName.isEmpty)
        ? defaultCommerceName
        : trimmedName;

    final addrTrim = data.address?.trim();
    final address =
        (addrTrim == null || addrTrim.isEmpty) ? null : addrTrim;

    final descTrim = data.description?.trim();
    final description =
        (descTrim == null || descTrim.isEmpty) ? null : descTrim;

    final localImagePath = data.imagePath?.trim();
    final hasLocalLogo =
        localImagePath != null && localImagePath.isNotEmpty;

    final cacheService = ref.read(merchantProfileCacheServiceProvider);
    final cachedData = await cacheService.loadProfile();

    final basicsResult =
        await ref.read(getUserProfileBasicsProvider).call(userId);
    final basics = basicsResult.fold((_) => null, (b) => b);

    String email = cachedData['email'] ??
        basics?.email ??
        user.email ??
        firebase_auth.FirebaseAuth.instance.currentUser?.email ??
        '';
    String phone = data.phoneNumber ??
        cachedData['phone'] ??
        basics?.phone ??
        user.phoneNumber ??
        firebase_auth.FirebaseAuth.instance.currentUser?.phoneNumber ??
        '';
    String city = cachedData['city'] ?? basics?.city ?? '';
    final websiteUrl = data.websiteUrl?.trim().isEmpty == true
        ? null
        : data.websiteUrl?.trim();

    email = email.trim();
    if (email.isEmpty) {
      email = 'demo@example.com';
    }
    phone = phone.trim();
    if (phone.isEmpty) {
      phone = '+33123456789';
    }
    city = city.trim();
    if (city.isEmpty) {
      city = defaultCityPlaceholder;
    }

    String? logoUrl;
    String? bannerUrl;
    var didUploadLogo = false;
    var didUploadBanner = false;
    final localBannerPath = data.bannerImagePath?.trim();

    if (hasLocalLogo) {
      final uploadLogoResult =
          await ref.read(storage_providers.uploadLogoProvider).call(
                filePath: localImagePath,
                merchantId: userId,
              );
      logoUrl = uploadLogoResult.fold((_) => null, (url) => url);
      didUploadLogo = logoUrl != null && logoUrl.isNotEmpty;
      if (!didUploadLogo) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec du téléversement.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }
    }

    if (localBannerPath != null && localBannerPath.isNotEmpty) {
      final uploadResult =
          await ref.read(storage_providers.uploadBannerProvider).call(
                filePath: localBannerPath,
                merchantId: userId,
              );
      bannerUrl = uploadResult.fold((_) => null, (url) => url);
      didUploadBanner = bannerUrl != null && bannerUrl.isNotEmpty;
    }

    try {
      await cacheService.saveProfile(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        city: city,
        address: address,
        category: data.categoryTitle,
        description: description,
        bannerImagePath: localBannerPath,
        profileImagePath: hasLocalLogo ? localImagePath : null,
        websiteUrl: websiteUrl,
        hoursJson: data.hoursJson,
      );
    } catch (_) {}

    bool firestoreSuccess = false;
    try {
      final completeOnboarding = ref.read(completeMerchantOnboardingProvider);
      final result = await completeOnboarding.call(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        city: city,
        address: address,
        categories: data.categoryTitle != null ? [data.categoryTitle!] : null,
        description: description,
        websiteUrl: websiteUrl,
        hours: data.hoursJson,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
      );
      firestoreSuccess = result.fold((_) => false, (_) => true);
    } catch (_) {}

    if (!firestoreSuccess) {
      final storageRepository = ref.read(storageRepositoryProvider);
      if (didUploadLogo) {
        await storageRepository.deleteImage('merchants/$userId/logo.png');
      }
      if (didUploadBanner) {
        await storageRepository.deleteImage('merchants/$userId/banner.png');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de créer votre commerce.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    ref.invalidate(storefront_providers.storefrontProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil commerçant créé avec succès!'),
          backgroundColor: MerchantOnboardingColors.primaryGold,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      widget.onComplete?.call();
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MerchantOnboardingFlowScreen(
      isPostSignup: true,
      onBack: widget.onBack ?? () {},
      onComplete: () {
        _saveFromOnboarding();
      },
    );
  }
}
