part of 'merchant_profile_form_screen.dart';

extension _MerchantProfileFormScreenActions on _MerchantProfileFormScreenState {
  Future<void> _saveFromOnboarding() async {
    if (_isSubmitting) return;
    _setSubmitting(true);
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) {
      _setSubmitting(false);
      return;
    }

    final user = authState.user;
    final userId = user.id;
    final data = ref.read(onboardingFlowProvider);

    const defaultCommerceName = 'Mon commerce';

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

    var basicsResult =
        await ref.read(getUserProfileBasicsProvider).call(userId);
    var basics = basicsResult.fold((_) => null, (b) => b);

    String email = cachedData['email'] ??
        basics?.email ??
        user.email ??
        '';
    String phone = data.phoneNumber ??
        cachedData['phone'] ??
        basics?.phone ??
        user.phoneNumber ??
        '';
    // City comes directly from the onboarding City step.
    final city = (data.city ?? '').trim();

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

    String? logoUrl;
    String? bannerUrl;
    var didUploadLogo = false;
    var didUploadBanner = false;
    final localBannerPath = data.bannerImagePath?.trim();

    if (hasLocalLogo) {
      final uploadLogoResult =
          await ref.read(uploadLogoProvider).call(
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
          _setSubmitting(false);
        }
        return;
      }
    }

    if (localBannerPath != null && localBannerPath.isNotEmpty) {
      final uploadResult =
          await ref.read(uploadBannerProvider).call(
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
      final deleteImage = ref.read(deleteStorageImageProvider);
      if (didUploadLogo) {
        await deleteImage.call('merchants/$userId/logo.png');
      }
      if (didUploadBanner) {
        await deleteImage.call('merchants/$userId/banner.png');
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
        _setSubmitting(false);
      }
      return;
    }

    ref.invalidate(storefrontProvider);

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
      _setSubmitting(false);
    }
  }
}
