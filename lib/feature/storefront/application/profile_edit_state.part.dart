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

  Future<void> initializeFrom(Storefront storefront) async {
    // Try to load existing data from cache first
    try {
      final authState = ref.read(auth_providers.authStateProvider);
      if (authState is Authenticated) {
        final cacheService = ref.read(merchant_providers.merchantProfileCacheServiceProvider);
        final cachedData = await cacheService.loadProfile();
        
        if (cachedData['userId'] == authState.user.id) {
          // Use cached data if available - ensure all values are non-null strings
          final cachedName = cachedData['name']?.toString().trim() ?? '';
          final cachedCategory = cachedData['category']?.toString().trim() ?? '';
          final cachedDescription = cachedData['description']?.toString().trim() ?? '';
          final cachedPhone = cachedData['phone']?.toString().trim() ?? '';
          final cachedAddress = cachedData['address']?.toString().trim() ?? '';
          final cachedCity = cachedData['city']?.toString().trim() ?? '';
          final cachedWebsiteUrl = cachedData['websiteUrl']?.toString().trim() ?? '';
          final cachedBannerPath = cachedData['bannerImagePath']?.toString().trim();
          final cachedProfilePath = cachedData['profileImagePath']?.toString().trim();
          
          // Use cached image paths if available, otherwise use storefront URLs
          final bannerUrl = cachedBannerPath != null && cachedBannerPath.isNotEmpty
              ? 'file://$cachedBannerPath'
              : storefront.bannerImageUrl;
          final profileUrl = cachedProfilePath != null && cachedProfilePath.isNotEmpty
              ? 'file://$cachedProfilePath'
              : storefront.profileImageUrl;
          
          state = state.copyWith(
            bannerImageUrl: bannerUrl,
            profileImageUrl: profileUrl,
            businessName: cachedName.isNotEmpty ? cachedName : storefront.merchantName,
            category: cachedCategory.isNotEmpty ? cachedCategory : (state.category.isEmpty ? 'Artisan Jewelry' : state.category),
            description: cachedDescription.isNotEmpty 
                ? cachedDescription
                : (state.description.isEmpty 
                    ? 'Décrivez votre activité en quelques lignes.' 
                    : state.description),
            phoneNumber: cachedPhone.isNotEmpty 
                ? cachedPhone
                : (state.phoneNumber.isEmpty ? '+33 6 12 34 56 78' : state.phoneNumber),
            websiteUrl: cachedWebsiteUrl.isNotEmpty 
                ? cachedWebsiteUrl
                : (state.websiteUrl.isEmpty ? 'www.votresite.com' : state.websiteUrl),
            address: cachedAddress.isNotEmpty 
                ? cachedAddress
                : (state.address.isEmpty ? 'Votre adresse' : state.address),
            city: CityInput.forEditField(
              cachedCity.isNotEmpty
                  ? cachedCity
                  : storefront.city,
            ),
          );
          return;
        }
      }
    } catch (e) {
      // Cache load failed - use storefront data with defaults
      // Log error but don't crash
    }
    
    // Fallback: use storefront data (from Firestore) with defaults
    final merchant = ref.read(merchant_providers.currentMerchantForOwnerProvider).valueOrNull;
    state = state.copyWith(
      bannerImageUrl: storefront.bannerImageUrl,
      profileImageUrl: storefront.profileImageUrl,
      businessName: storefront.merchantName,
      category: state.category.isEmpty ? 'Artisan Jewelry' : state.category,
      description: state.description.isEmpty
          ? 'Décrivez votre activité en quelques lignes.'
          : state.description,
      phoneNumber: (storefront.phone ?? state.phoneNumber).trim().isEmpty ? '+33 6 12 34 56 78' : (storefront.phone ?? state.phoneNumber),
      email: merchant?.email.isNotEmpty == true ? merchant!.email : '',
      websiteUrl: (storefront.websiteUrl ?? state.websiteUrl).trim().isEmpty ? 'www.votresite.com' : (storefront.websiteUrl ?? state.websiteUrl),
      address: (storefront.address ?? state.address).trim().isEmpty ? 'Votre adresse' : (storefront.address ?? state.address),
      city: CityInput.forEditField(storefront.city),
      welcomeGiftDescription: merchant?.welcomeGiftDescription ?? '',
      // Defensive read: anything other than the two known values falls
      // back to the entity default so the picker never shows a blank
      // state and the save path doesn't blindly forward garbage.
      merchantType: (merchant?.merchantType == 'b2b' ||
              merchant?.merchantType == 'b2c')
          ? merchant!.merchantType
          : 'b2c',
    );
  }

  void setBusinessName(String v) => state = state.copyWith(businessName: v);
  void setCategory(String v) => state = state.copyWith(category: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setPhoneNumber(String v) => state = state.copyWith(phoneNumber: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setWebsiteUrl(String v) => state = state.copyWith(websiteUrl: v);
  void setAddress(String v) => state = state.copyWith(address: v);
  void setCity(String v) => state = state.copyWith(city: v);
  void setWelcomeGiftDescription(String v) =>
      state = state.copyWith(welcomeGiftDescription: v);

  /// Setter validates against the wire allowlist; anything else is a
  /// no-op so the picker can never put the state into a bad shape.
  void setMerchantType(String v) {
    if (v != 'b2b' && v != 'b2c') return;
    state = state.copyWith(merchantType: v);
  }

  void setBannerImageUrl(String v) => state = state.copyWith(bannerImageUrl: v);
  void setProfileImageUrl(String v) => state = state.copyWith(profileImageUrl: v);
  void clearError() => state = state.copyWith(errorMessage: null);

  Future<void> save() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true);

    try {
      // Get current user ID
      final authState = ref.read(auth_providers.authStateProvider);
      if (authState is! Authenticated) {
        state = state.copyWith(isSaving: false);
        return;
      }

      final userId = authState.user.id;

      // Resolve the real merchant document ID from the user doc.
      // In MVP, merchantId == userId, but linkExistingMerchantToUser can differ.
      final firestore = ref.read(firebaseFirestoreProvider);
      final userDoc = await firestore.collection('users').doc(userId).get();
      final merchantId =
          ((userDoc.data()?['merchant_id'] as String?)?.trim().isNotEmpty ?? false)
              ? (userDoc.data()?['merchant_id'] as String).trim()
              : userId;
      
      // Extract logo file path if a new image was selected
      String? logoFilePath;
      if (state.profileImageUrl.startsWith('file://')) {
        final path = state.profileImageUrl.substring(7);
        final file = File(path);
        if (file.existsSync()) {
          logoFilePath = path;
        }
      }

      // Extract banner file path if a new image was selected
      String? bannerFilePath;
      if (state.bannerImageUrl.startsWith('file://')) {
        final path = state.bannerImageUrl.substring(7);
        final file = File(path);
        if (file.existsSync()) {
          bannerFilePath = path;
        }
      }

      // Prepare storefront update data (all fields saved to Firestore)
      final displayName = state.businessName.trim().isNotEmpty
          ? state.businessName.trim()
          : null;
      final description = state.description.trim().isNotEmpty
          ? state.description.trim()
          : null;
      final categories = state.category.trim().isNotEmpty
          ? [state.category.trim()]
          : null;
      final phone = state.phoneNumber.trim().isNotEmpty
          ? state.phoneNumber.trim()
          : null;
      final address = state.address.trim().isNotEmpty
          ? state.address.trim()
          : null;
      final city = CityInput.forFirestore(state.city);
      final websiteUrl = state.websiteUrl.trim().isNotEmpty
          ? state.websiteUrl.trim()
          : null;

      final email = state.email.trim().isNotEmpty ? state.email.trim() : null;
      final welcomeGiftDescription =
          state.welcomeGiftDescription.trim().isNotEmpty
              ? state.welcomeGiftDescription.trim()
              : '';

      // Use UpdateStorefront use case to upload images and update Firestore
      final updateStorefront = ref.read(merchant_providers.updateStorefrontProvider);
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
        clearMerchantCityField: city == null,
      );

      result.fold(
        (failure) {
          // Save failed - set error message (already in French/English from failure)
          state = state.copyWith(
            errorMessage: failure.message,
            isSaving: false,
          );
          return; // Exit early on error
        },
        (merchant) {
          // Success - storefront updated in Firestore
          // Logo uploaded and URL saved
          // Clear any previous error
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

      // Also save to cache as fallback (for demo mode)
      final cacheService = ref.read(merchant_providers.merchantProfileCacheServiceProvider);
      final existingCache = await cacheService.loadProfile();
      
      // Extract image paths for cache (preserve local paths for offline access)
      String? profilePath;
      if (logoFilePath != null) {
        profilePath = logoFilePath;
      } else if (state.profileImageUrl.isEmpty) {
        profilePath = null; // User deleted image
      } else if (state.profileImageUrl.startsWith('file://')) {
        final path = state.profileImageUrl.substring(7);
        if (File(path).existsSync()) {
          profilePath = path;
        }
      } else if (!state.profileImageUrl.contains('aida-public') && state.profileImageUrl.isNotEmpty) {
        profilePath = result.fold(
          (_) => existingCache['profileImagePath'],
          (merchant) => merchant.logoUrl,
        );
      }

      // Extract banner path/URL for cache
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

      // Save to cache (fallback for demo mode)
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
        category: state.category.trim().isNotEmpty ? state.category.trim() : null,
        description: description,
        profileImagePath: profilePath,
        bannerImagePath: bannerPath,
        websiteUrl: state.websiteUrl.trim().isNotEmpty ? state.websiteUrl.trim() : null,
      );

      // Note: Following DDD principles, provider invalidation should be done in presentation layer
      // The save operation completes successfully - presentation layer will handle refresh
    } catch (e) {
      // Unexpected error - this should not happen, but handle gracefully
      // Error will be shown by presentation layer
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
