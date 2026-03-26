import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../application/providers.dart';
import '../../storage/application/providers.dart' as storage_providers;
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
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final user = authState.user;
    final userId = user.id;
    final data = ref.read(onboardingFlowProvider);

    final name = data.fullName?.trim();
    if (name == null || name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le nom du commerce est requis'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final cacheService = ref.read(merchantProfileCacheServiceProvider);
    final cachedData = await cacheService.loadProfile();

    final basicsResult = await ref.read(getUserProfileBasicsProvider).call(userId);
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
    String city = cachedData['city'] ??
        basics?.city ??
        '';
    final websiteUrl = data.websiteUrl?.trim().isEmpty == true ? null : data.websiteUrl?.trim();

    email = email.trim().isEmpty ? 'demo@example.com' : email.trim();
    phone = phone.trim().isEmpty ? '+33123456789' : phone.trim();
    city = city.trim().isEmpty ? 'Paris' : city.trim();

    String? logoUrl;
    String? bannerUrl;
    final localImagePath = data.imagePath?.trim();
    final localBannerPath = data.bannerImagePath?.trim();
    if (localImagePath != null && localImagePath.isNotEmpty) {
      final uploadResult = await ref.read(storage_providers.uploadLogoProvider).call(
            filePath: localImagePath,
            merchantId: userId,
          );
      logoUrl = uploadResult.fold((_) => null, (url) => url);
    }
    if (localBannerPath != null && localBannerPath.isNotEmpty) {
      final uploadResult = await ref.read(storage_providers.uploadBannerProvider).call(
            filePath: localBannerPath,
            merchantId: userId,
          );
      bannerUrl = uploadResult.fold((_) => null, (url) => url);
    }

    try {
      await cacheService.saveProfile(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        city: city,
        address: data.address,
        category: data.categoryTitle,
        description: data.description,
        bannerImagePath: localBannerPath,
        profileImagePath: localImagePath,
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
        address: data.address,
        categories: data.categoryTitle != null ? [data.categoryTitle!] : null,
        description: data.description,
        websiteUrl: websiteUrl,
        hours: data.hoursJson,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
      );
      firestoreSuccess = result.fold((_) => false, (_) => true);
    } catch (_) {}

    if (!firestoreSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Échec de sauvegarde en base de données. Vérifiez la connexion et réessayez.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
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
