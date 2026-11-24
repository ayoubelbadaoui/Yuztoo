part of 'merchant_profile_form_screen.dart';

/// Offline / very slow network: Firestore and Storage calls otherwise wait
/// for minutes and leave « Création… » spinning with no way out.
const Duration _kReadTimeout = Duration(seconds: 10);
const Duration _kUploadTimeout = Duration(seconds: 60);
const Duration _kWriteTimeout = Duration(seconds: 30);

/// [future] or null when it fails / takes longer than [limit].
Future<T?> _orNullAfter<T>(Future<T> future, Duration limit) async {
  try {
    return await future.timeout(limit);
  } catch (_) {
    return null;
  }
}

extension _MerchantProfileFormScreenActions on _MerchantProfileFormScreenState {
  Future<void> _saveFromOnboarding() async {
    if (_isSubmitting) return;
    _setSubmitting(true);
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) {
      _setSubmitting(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expirée. Reconnectez-vous puis réessayez.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    final address = (addrTrim == null || addrTrim.isEmpty) ? null : addrTrim;

    final descTrim = data.description?.trim();
    final description =
        (descTrim == null || descTrim.isEmpty) ? null : descTrim;

    final localImagePath = data.imagePath?.trim();
    final hasLocalLogo = localImagePath != null && localImagePath.isNotEmpty;

    final cacheService = ref.read(merchantProfileCacheServiceProvider);
    final cachedData = await cacheService.loadProfile();

    final basicsResult = await _orNullAfter(
      ref.read(getUserProfileBasicsProvider).call(userId),
      _kReadTimeout,
    );
    final basics = basicsResult?.fold((_) => null, (b) => b);

    // Source-of-truth for the merchant contact email is the address step
    // of the onboarding flow (data.contactEmail). Cached / basics / auth
    // values are kept only as graceful fallbacks for older builds where
    // the step did not exist. The legacy `demo@example.com` placeholder
    // is now treated as "no email" so we never persist it again.
    // Fallbacks skip Apple relay addresses (`@privaterelay.appleid.com`):
    // as a public contact email they silently bounce client mail. The
    // address step's own value (typed by the merchant) is kept as is.
    String? fallbackEmail(String? v) =>
        EmailValidator.isPublicContactCandidate(v) ? v : null;
    String email = (data.contactEmail ??
            fallbackEmail(cachedData['email']) ??
            fallbackEmail(basics?.email) ??
            fallbackEmail(user.email) ??
            '')
        .trim();
    if (EmailValidator.isPlaceholderOrEmpty(email)) email = '';
    String phone = data.phoneNumber ??
        cachedData['phone'] ??
        basics?.phone ??
        user.phoneNumber ??
        '';
    // City comes directly from the onboarding City step.
    final city = persistableMerchantCity(data.city) ?? (data.city ?? '').trim();

    final websiteUrl = data.websiteUrl?.trim().isEmpty == true
        ? null
        : data.websiteUrl?.trim();

    // Hard gate: a valid email must be present. The new onboarding flow
    // collects it at the address step (and validates the format there);
    // failing here only happens for legacy users who skipped that step
    // (e.g. resumed mid-flow on an older build). Surface a clear error
    // and bail out — DO NOT silently substitute a placeholder.
    if (!EmailValidator.isValid(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Adresse email manquante. Revenez à l\'étape « Votre adresse » '
              'pour la renseigner.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        _setSubmitting(false);
      }
      return;
    }
    phone = phone.trim();

    String? logoUrl;
    String? bannerUrl;
    var didUploadLogo = false;
    var didUploadBanner = false;
    final localBannerPath = data.bannerImagePath?.trim();

    if (hasLocalLogo) {
      final uploadLogoResult = await _orNullAfter(
        ref.read(uploadLogoProvider).call(
              filePath: localImagePath,
              merchantId: userId,
            ),
        _kUploadTimeout,
      );
      logoUrl = uploadLogoResult?.fold((_) => null, (url) => url);
      didUploadLogo = logoUrl != null && logoUrl.isNotEmpty;
      if (!didUploadLogo) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Échec du téléversement du logo. Vérifiez votre connexion '
                'puis réessayez.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _setSubmitting(false);
        }
        return;
      }
    }

    if (localBannerPath != null && localBannerPath.isNotEmpty) {
      final uploadResult = await _orNullAfter(
        ref.read(uploadBannerProvider).call(
              filePath: localBannerPath,
              merchantId: userId,
            ),
        _kUploadTimeout,
      );
      bannerUrl = uploadResult?.fold((_) => null, (url) => url);
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
        category: data.subcategoryTitle ?? data.categoryTitle,
        description: description,
        bannerImagePath: localBannerPath,
        profileImagePath: hasLocalLogo ? localImagePath : null,
        websiteUrl: websiteUrl,
        hoursJson: data.hoursJson,
      );
    } catch (_) {}

    // Persist owner identity (firstName/lastName/DOB) to users/{uid}.
    final ownerFirst = data.ownerFirstName?.trim();
    final ownerLast = data.ownerLastName?.trim();
    final ownerDob = data.ownerDateOfBirth;
    if ((ownerFirst?.isNotEmpty == true) ||
        (ownerLast?.isNotEmpty == true) ||
        ownerDob != null) {
      try {
        await ref
            .read(auth_providers.updateClientBasicInfoProvider)
            .call(
              uid: userId,
              firstName: ownerFirst,
              lastName: ownerLast,
              dateOfBirth: ownerDob,
            )
            .timeout(_kWriteTimeout);
      } catch (_) {}
    }

    bool firestoreSuccess = false;
    var timedOut = false;
    try {
      // Profile "Catégorie" shows the specialty; write that into `categories`
      // so display and Firestore stay aligned. Parent sector stays on
      // category_id / categoryTitle for taxonomy.
      final categoriesWritten = data.subcategoryTitle != null
          ? [data.subcategoryTitle!]
          : (data.categoryTitle != null ? [data.categoryTitle!] : null);
      LoggerService.logInfo(
        'Onboarding persisting merchant category',
        context: <String, dynamic>{
          'userId': userId,
          'merchantType': data.merchantType,
          'categoryId': data.categoryId,
          'categoryTitle': data.categoryTitle,
          'subcategoryTitle': data.subcategoryTitle,
          'categoriesWritten': categoriesWritten,
        },
      );
      final completeOnboarding = ref.read(completeMerchantOnboardingProvider);
      final result = await completeOnboarding.call(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        city: city,
        commune: data.commune,
        address: address,
        categories: categoriesWritten,
        description: description,
        websiteUrl: websiteUrl,
        hours: data.hoursJson,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        merchantType: data.merchantType,
        categoryId: data.categoryId,
        subcategoryTitle: data.subcategoryTitle,
      ).timeout(_kWriteTimeout);
      firestoreSuccess = result.fold((_) => false, (_) => true);
      LoggerService.logInfo(
        'Onboarding persist merchant category result',
        context: <String, dynamic>{
          'userId': userId,
          'success': firestoreSuccess,
        },
      );
    } on TimeoutException {
      timedOut = true;
    } catch (_) {}

    if (firestoreSuccess) {
      unawaited(OnboardingCompletionCache.markCompleted('merchant', userId));
      _draftClosed = true;
      unawaited(MerchantOnboardingDraftStore.clear(userId));
    }

    if (!firestoreSuccess) {
      final deleteImage = ref.read(deleteStorageImageProvider);
      // Not after a timeout: the queued write may still land and would then
      // point at deleted images. Retrying re-uploads them anyway.
      if (!timedOut && didUploadLogo) {
        await _orNullAfter(
          deleteImage.call('merchants/$userId/logo.png'),
          _kReadTimeout,
        );
      }
      if (!timedOut && didUploadBanner) {
        await _orNullAfter(
          deleteImage.call('merchants/$userId/banner.png'),
          _kReadTimeout,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              timedOut
                  ? 'Connexion trop lente. Vérifiez votre réseau puis réessayez.'
                  : 'Impossible de créer votre commerce.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        _setSubmitting(false);
      }
      return;
    }

    // Navigate FIRST, then run the cache invalidations and the auth-user
    // refresh in the background. Mirrors the symmetrical fix in
    // client_onboarding_screen.dart: any async auth refresh that happens
    // BEFORE widget.onComplete() can re-emit the auth state mid-await and
    // dump the user on splash for the duration of role-lookup retries.
    // Synchronous `ref.invalidate` is safe to run after navigation —
    // dependents re-fetch on next read, and the storefront screen reads
    // through the freshly-invalidated providers on its first build.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // A failed cover upload is not blocking, but must not be silent.
          content: Text(
            localBannerPath != null &&
                    localBannerPath.isNotEmpty &&
                    !didUploadBanner
                ? 'Profil créé. La photo de couverture n\'a pas pu être '
                    'envoyée : ajoutez-la depuis votre profil.'
                : 'Profil commerçant créé avec succès.',
          ),
          backgroundColor: MerchantOnboardingColors.primaryGold,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      widget.onComplete?.call();
      _setSubmitting(false);
      ref.invalidate(storefrontProvider);
      invalidateDiscoveryCatalogWidget(ref);
      ref.invalidate(auth_providers.connectedCitiesProvider(userId));
      // Pull the freshly-written displayName / city / phone into the
      // AuthUser. The shell's _handleAuthStateChange short-circuits the
      // re-emission (same uid + not on splash + not navigating) so this
      // is now safe to fire after navigation.
      unawaited(refreshUserProfileCacheWidget(
        ref,
        uid: userId,
        isMerchant: true,
        cityChanged: city.isNotEmpty,
      ));
    }
  }
}
