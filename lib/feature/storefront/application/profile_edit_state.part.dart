part of 'profile_edit_state.dart';

class StorefrontProfileEditNotifier
    extends StateNotifier<StorefrontProfileEditState> {
  StorefrontProfileEditNotifier(this.ref)
      : super(
          const StorefrontProfileEditState(
            bannerImageUrl: '',
            profileImageUrl: '',
            businessName: '',
            category: '',
            categoryId: '',
            categoryTitle: '',
            subcategoryTitle: '',
            description: '',
            phoneNumber: '',
            email: '',
            websiteUrl: '',
            address: '',
            city: '',
            welcomeGiftDescription: '',
          ),
        );

  final Ref ref;

  /// Values the pre-taxonomy, food-only category dropdown could write.
  static const _legacyFoodOptions = {
    'Café / Bar',
    'Restaurant / Brasserie',
    'Restauration rapide',
    'Boulangerie / Pâtisserie',
    'Boucherie / Charcuterie',
    'Poissonnerie',
    'Fromagerie / Crèmerie',
    'Confiserie / Chocolatier',
    'Glacier',
    'Caviste & Épicerie',
    'Maraîcher',
    'Ferme / Produit Locaux',
    'Artisans marché',
    'Boutique BIO',
    'Traiteur',
  };

  static bool _isCorruptedCategory(String value, String? merchantType) =>
      value == 'Artisan Jewelry' ||
      (merchantType == 'b2b' && _legacyFoodOptions.contains(value));

  /// Resolve main category id + specialty from a merchant document.
  static ({String categoryId, String categoryTitle, String subcategoryTitle})
      _taxonomyFromMerchant(Merchant? merchant) {
    final merchantType = merchant?.merchantType;
    final storedId = merchant?.categoryId?.trim() ?? '';
    final storedSub = merchant?.subcategoryTitle?.trim() ?? '';
    final storedCategories = merchant?.categories ?? const <String>[];
    final storedFirst = storedCategories.isNotEmpty
        ? storedCategories.first.trim()
        : '';

    final cleanSub = storedSub.isNotEmpty &&
            !_isCorruptedCategory(storedSub, merchantType)
        ? storedSub
        : '';
    final cleanFirst = storedFirst.isNotEmpty &&
            !_isCorruptedCategory(storedFirst, merchantType)
        ? storedFirst
        : '';

    // Prefer persisted category_id when it still exists in the catalog.
    final byId = MerchantCategoryCatalog.byId(storedId);
    if (byId != null) {
      final specialty = cleanSub.isNotEmpty
          ? cleanSub
          : (MerchantCategoryCatalog.isOtherCategoryId(byId.id)
              ? cleanFirst
              : '');
      return (
        categoryId: byId.id,
        categoryTitle: byId.title,
        subcategoryTitle: specialty,
      );
    }

    // Reverse-lookup specialty → parent sector.
    final specialtyHint = cleanSub.isNotEmpty ? cleanSub : cleanFirst;
    if (specialtyHint.isNotEmpty) {
      for (final audience in MerchantAudience.values) {
        for (final category in MerchantCategoryCatalog.forAudience(audience)) {
          for (final sub
              in MerchantSubcategoryCatalog.forCategory(category.id)) {
            if (sub.title == specialtyHint) {
              return (
                categoryId: category.id,
                categoryTitle: category.title,
                subcategoryTitle: specialtyHint,
              );
            }
          }
          if (category.title == specialtyHint) {
            return (
              categoryId: category.id,
              categoryTitle: category.title,
              subcategoryTitle: specialtyHint,
            );
          }
        }
      }

      // Free-text specialty with no parent → treat as "Autre".
      final otherId = merchantType == 'b2b' ? 'autres_pro' : 'autre';
      final other = MerchantCategoryCatalog.byId(otherId);
      return (
        categoryId: otherId,
        categoryTitle: other?.title ?? 'Autre',
        subcategoryTitle: specialtyHint,
      );
    }

    return (categoryId: '', categoryTitle: '', subcategoryTitle: '');
  }

  static String _specialtyDisplay({
    required String subcategoryTitle,
    required String categoryTitle,
  }) {
    final sub = subcategoryTitle.trim();
    if (sub.isNotEmpty) return sub;
    return categoryTitle.trim();
  }

  Future<void> initializeFrom(Storefront storefront) async {
    Merchant? merchant;
    try {
      merchant = await ref
          .read(merchant_providers.currentMerchantForOwnerProvider.future);
    } catch (_) {
      merchant = null;
    }
    if (!mounted) return;

    final taxonomy = _taxonomyFromMerchant(merchant);
    final firestoreMerchantType = merchant?.merchantType;
    final resolvedMerchantType =
        (firestoreMerchantType == 'b2b' || firestoreMerchantType == 'b2c')
            ? firestoreMerchantType!
            : 'b2c';
    final specialty = _specialtyDisplay(
      subcategoryTitle: taxonomy.subcategoryTitle,
      categoryTitle: taxonomy.categoryTitle,
    );

    LoggerService.logInfo(
      'Profile edit category fetch (merchant doc)',
      context: <String, dynamic>{
        'merchantId': merchant?.id,
        'merchantType': firestoreMerchantType,
        'firestoreCategoryId': merchant?.categoryId,
        'firestoreCategories': merchant?.categories ?? const <String>[],
        'firestoreSubcategoryTitle': merchant?.subcategoryTitle,
        'resolvedCategoryId': taxonomy.categoryId,
        'resolvedCategoryTitle': taxonomy.categoryTitle,
        'resolvedSubcategoryTitle': taxonomy.subcategoryTitle,
      },
    );

    try {
      final authState = ref.read(auth_providers.authStateProvider);
      if (authState is Authenticated) {
        final cacheService =
            ref.read(merchant_providers.merchantProfileCacheServiceProvider);
        final cachedData = await cacheService.loadProfile();

        if (cachedData['userId'] == authState.user.id) {
          final cachedName = cachedData['name']?.toString().trim() ?? '';
          final cachedDescription =
              cachedData['description']?.toString().trim() ?? '';
          final cachedPhone = cachedData['phone']?.toString().trim() ?? '';
          final cachedAddress = cachedData['address']?.toString().trim() ?? '';
          final cachedCity = cachedData['city']?.toString().trim() ?? '';
          final cachedWebsiteUrl =
              cachedData['websiteUrl']?.toString().trim() ?? '';
          final cachedBannerPath =
              cachedData['bannerImagePath']?.toString().trim();
          final cachedProfilePath =
              cachedData['profileImagePath']?.toString().trim();

          final bannerUrl =
              cachedBannerPath != null && cachedBannerPath.isNotEmpty
                  ? 'file://$cachedBannerPath'
                  : storefront.bannerImageUrl;
          final profileUrl =
              cachedProfilePath != null && cachedProfilePath.isNotEmpty
                  ? 'file://$cachedProfilePath'
                  : storefront.profileImageUrl;

          LoggerService.logInfo(
            'Profile edit category resolved',
            context: <String, dynamic>{
              'source': 'merchant',
              'categoryId': taxonomy.categoryId,
              'categoryTitle': taxonomy.categoryTitle,
              'subcategoryTitle': taxonomy.subcategoryTitle,
              'resolvedMerchantType': resolvedMerchantType,
            },
          );

          state = state.copyWith(
            bannerImageUrl: bannerUrl,
            profileImageUrl: profileUrl,
            businessName:
                cachedName.isNotEmpty ? cachedName : storefront.merchantName,
            category: specialty,
            categoryId: taxonomy.categoryId,
            categoryTitle: taxonomy.categoryTitle,
            subcategoryTitle: taxonomy.subcategoryTitle,
            description: cachedDescription.isNotEmpty
                ? cachedDescription
                : (state.description.isEmpty
                    ? 'Décrivez votre activité en quelques lignes.'
                    : state.description),
            phoneNumber: cachedPhone.isNotEmpty
                ? cachedPhone
                : (state.phoneNumber.isEmpty
                    ? '+33 6 12 34 56 78'
                    : state.phoneNumber),
            websiteUrl: cachedWebsiteUrl.isNotEmpty
                ? cachedWebsiteUrl
                : (state.websiteUrl.isEmpty
                    ? 'www.votresite.com'
                    : state.websiteUrl),
            address: cachedAddress.isNotEmpty
                ? cachedAddress
                : (state.address.isEmpty ? 'Votre adresse' : state.address),
            city: CityInput.forEditField(
              cachedCity.isNotEmpty ? cachedCity : storefront.city,
            ),
            merchantType: resolvedMerchantType,
          );
          return;
        }
      }
    } catch (e) {
      LoggerService.logDebug(
        'Profile edit cache load failed; using merchant fallback',
        context: <String, dynamic>{'error': e.toString()},
      );
    }

    LoggerService.logInfo(
      'Profile edit category resolved (merchant fallback branch)',
      context: <String, dynamic>{
        'categoryId': taxonomy.categoryId,
        'categoryTitle': taxonomy.categoryTitle,
        'subcategoryTitle': taxonomy.subcategoryTitle,
        'resolvedMerchantType': resolvedMerchantType,
      },
    );
    state = state.copyWith(
      bannerImageUrl: storefront.bannerImageUrl,
      profileImageUrl: storefront.profileImageUrl,
      businessName: storefront.merchantName,
      category: specialty,
      categoryId: taxonomy.categoryId,
      categoryTitle: taxonomy.categoryTitle,
      subcategoryTitle: taxonomy.subcategoryTitle,
      description: state.description.isEmpty
          ? 'Décrivez votre activité en quelques lignes.'
          : state.description,
      phoneNumber: (storefront.phone ?? state.phoneNumber).trim().isEmpty
          ? '+33 6 12 34 56 78'
          : (storefront.phone ?? state.phoneNumber),
      email: merchant?.email.isNotEmpty == true ? merchant!.email : '',
      websiteUrl: (storefront.websiteUrl ?? state.websiteUrl).trim().isEmpty
          ? 'www.votresite.com'
          : (storefront.websiteUrl ?? state.websiteUrl),
      address: (storefront.address ?? state.address).trim().isEmpty
          ? 'Votre adresse'
          : (storefront.address ?? state.address),
      city: CityInput.forEditField(storefront.city),
      welcomeGiftDescription: merchant?.welcomeGiftDescription ?? '',
      merchantType: resolvedMerchantType,
    );
  }

  void setBusinessName(String v) => state = state.copyWith(businessName: v);

  /// Select a main sector; clears specialty so the merchant re-picks (or types).
  void setMainCategory(String categoryId, String categoryTitle) {
    LoggerService.logInfo(
      'Profile edit main category changed',
      context: <String, dynamic>{
        'previousCategoryId': state.categoryId,
        'previousCategoryTitle': state.categoryTitle,
        'newCategoryId': categoryId,
        'newCategoryTitle': categoryTitle,
        'merchantType': state.merchantType,
      },
    );
    state = state.copyWith(
      categoryId: categoryId,
      categoryTitle: categoryTitle,
      subcategoryTitle: '',
      category: '',
    );
  }

  void setSubcategoryTitle(String v) {
    final trimmed = v.trim();
    LoggerService.logInfo(
      'Profile edit subcategory changed',
      context: <String, dynamic>{
        'categoryId': state.categoryId,
        'previousSubcategoryTitle': state.subcategoryTitle,
        'newSubcategoryTitle': trimmed,
        'isOtherCategory': state.isOtherCategory,
      },
    );
    state = state.copyWith(
      subcategoryTitle: trimmed,
      category: _specialtyDisplay(
        subcategoryTitle: trimmed,
        categoryTitle: state.categoryTitle,
      ),
    );
  }

  @Deprecated('Use setMainCategory / setSubcategoryTitle')
  void setCategory(String v) => setSubcategoryTitle(v);

  void setDescription(String v) => state = state.copyWith(description: v);
  void setPhoneNumber(String v) => state = state.copyWith(phoneNumber: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setWebsiteUrl(String v) => state = state.copyWith(websiteUrl: v);
  void setAddress(String v) => state = state.copyWith(address: v);
  void setCity(String v) => state = state.copyWith(city: v);
  void setWelcomeGiftDescription(String v) =>
      state = state.copyWith(welcomeGiftDescription: v);

  void setMerchantType(String v) {
    if (v != 'b2b' && v != 'b2c') return;
    state = state.copyWith(merchantType: v);
  }

  void setBannerImageUrl(String v) => state = state.copyWith(bannerImageUrl: v);
  void setProfileImageUrl(String v) =>
      state = state.copyWith(profileImageUrl: v);
  void clearError() => state = state.copyWith(errorMessage: null);

  Future<void> save() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true);

    try {
      final authState = ref.read(auth_providers.authStateProvider);
      if (authState is! Authenticated) {
        state = state.copyWith(isSaving: false);
        return;
      }

      final userId = authState.user.id;

      final firestore = ref.read(firebaseFirestoreProvider);
      final userDoc = await firestore.collection('users').doc(userId).get();
      final merchantId =
          ((userDoc.data()?['merchant_id'] as String?)?.trim().isNotEmpty ??
                  false)
              ? (userDoc.data()?['merchant_id'] as String).trim()
              : userId;

      String? logoFilePath;
      if (state.profileImageUrl.startsWith('file://')) {
        final path = state.profileImageUrl.substring(7);
        final file = File(path);
        if (file.existsSync()) {
          logoFilePath = path;
        }
      }

      String? bannerFilePath;
      if (state.bannerImageUrl.startsWith('file://')) {
        final path = state.bannerImageUrl.substring(7);
        final file = File(path);
        if (file.existsSync()) {
          bannerFilePath = path;
        }
      }

      final displayName = state.businessName.trim().isNotEmpty
          ? state.businessName.trim()
          : null;
      final description = state.description.trim().isNotEmpty
          ? state.description.trim()
          : null;
      final specialty = _specialtyDisplay(
        subcategoryTitle: state.subcategoryTitle,
        categoryTitle: state.categoryTitle,
      );
      final categories = specialty.isNotEmpty ? [specialty] : null;
      final phone = state.phoneNumber.trim().isNotEmpty
          ? state.phoneNumber.trim()
          : null;
      final address =
          state.address.trim().isNotEmpty ? state.address.trim() : null;
      final city = CityInput.forFirestore(state.city);
      final websiteUrl = state.websiteUrl.trim().isNotEmpty
          ? state.websiteUrl.trim()
          : null;

      final email = state.email.trim().isNotEmpty ? state.email.trim() : null;
      final welcomeGiftDescription =
          state.welcomeGiftDescription.trim().isNotEmpty
              ? state.welcomeGiftDescription.trim()
              : '';

      LoggerService.logInfo(
        'Profile edit saving category',
        context: <String, dynamic>{
          'merchantId': merchantId,
          'categoryId': state.categoryId,
          'categoryTitle': state.categoryTitle,
          'subcategoryTitle': state.subcategoryTitle,
          'categoriesWritten': categories,
          'isOtherCategory': state.isOtherCategory,
        },
      );

      final updateStorefront =
          ref.read(merchant_providers.updateStorefrontProvider);
      final result = await updateStorefront.call(
        merchantId: merchantId,
        displayName: displayName,
        description: description,
        categories: categories,
        logoFilePath: logoFilePath,
        bannerFilePath: bannerFilePath,
        phone: phone,
        email: email,
        address: address,
        city: city,
        websiteUrl: websiteUrl,
        welcomeGiftDescription: welcomeGiftDescription,
        merchantType: state.merchantType,
        categoryId: state.categoryId.trim().isNotEmpty
            ? state.categoryId.trim()
            : '',
        subcategoryTitle: state.subcategoryTitle.trim(),
        clearMerchantCityField: city == null,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            errorMessage: failure.message,
            isSaving: false,
          );
          return;
        },
        (merchant) {
          state = state.copyWith(errorMessage: null);
          final auth = ref.read(auth_providers.authControllerProvider);
          if (auth is Authenticated) {
            unawaited(refreshUserProfileCache(
              ref,
              uid: auth.user.id,
              isMerchant: true,
              cityChanged: city != null,
            ));
          } else {
            invalidateDiscoveryCatalog(ref);
            ref.invalidate(merchant_providers.storefrontProvider);
          }
        },
      );

      final cacheService =
          ref.read(merchant_providers.merchantProfileCacheServiceProvider);
      final existingCache = await cacheService.loadProfile();

      String? profilePath;
      if (logoFilePath != null) {
        profilePath = logoFilePath;
      } else if (state.profileImageUrl.isEmpty) {
        profilePath = null;
      } else if (state.profileImageUrl.startsWith('file://')) {
        final path = state.profileImageUrl.substring(7);
        if (File(path).existsSync()) {
          profilePath = path;
        }
      } else if (!state.profileImageUrl.contains('aida-public') &&
          state.profileImageUrl.isNotEmpty) {
        profilePath = result.fold(
          (_) => existingCache['profileImagePath'],
          (merchant) => merchant.logoUrl,
        );
      }

      String? bannerPath;
      if (bannerFilePath != null) {
        bannerPath = bannerFilePath;
      } else if (state.bannerImageUrl.isEmpty) {
        bannerPath = null;
      } else if (state.bannerImageUrl.startsWith('file://')) {
        final path = state.bannerImageUrl.substring(7);
        if (File(path).existsSync()) {
          bannerPath = path;
        }
      } else {
        bannerPath = result.fold(
          (_) => existingCache['bannerImagePath'],
          (merchant) => merchant.bannerUrl,
        );
      }

      await cacheService.saveProfile(
        userId: userId,
        name: displayName ?? existingCache['name'] ?? 'Nom du commerce',
        email: existingCache['email'] ?? 'demo@example.com',
        phone: state.phoneNumber.trim().isNotEmpty
            ? state.phoneNumber.trim()
            : (existingCache['phone'] ?? '+33123456789'),
        city: CityInput.forFirestore(state.city) ??
            (CityInput.isPlaceholder(existingCache['city']?.toString())
                ? ''
                : (existingCache['city']?.toString().trim() ?? '')),
        address: state.address.trim().isNotEmpty ? state.address.trim() : null,
        category: specialty.isNotEmpty ? specialty : null,
        description: description,
        profileImagePath: profilePath,
        bannerImagePath: bannerPath,
        websiteUrl:
            state.websiteUrl.trim().isNotEmpty ? state.websiteUrl.trim() : null,
      );
    } catch (e) {
      // Unexpected error — presentation layer surfaces state.errorMessage.
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
