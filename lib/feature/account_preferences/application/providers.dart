import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/personal_profile_image_cache.dart';
import '../infrastructure/shared_preferences_personal_profile_image_cache.dart';
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';

export '../../auth/core/application/providers.dart'
    show
        authStateProvider,
        userProfileBasicsProvider,
        connectedCitiesProvider,
        setConnectedCitiesProvider;

export '../../auth/core/application/state/auth_state.dart'
    show
        AuthState,
        Authenticated;

export '../../storefront/application/providers.dart' show storefrontProvider;

export '../../profile/application/refresh_user_profile_cache.dart'
    show refreshUserProfileCacheWidget;

final personalProfileImageCacheProvider =
    Provider<PersonalProfileImageCache>((ref) {
  return SharedPreferencesPersonalProfileImageCache();
});

/// Cached local file path for the user's personal profile photo (not merchant logo).
final personalProfileImagePathProvider =
    FutureProvider.family<String?, String>((ref, userId) async {
  final cache = ref.watch(personalProfileImageCacheProvider);
  return cache.getCachedImagePath(userId);
});

/// Number of clients who follow a given merchant (their follower / partner count).
final merchantFollowerCountProvider =
    FutureProvider.family<int, String>((ref, merchantId) async {
  if (merchantId.isEmpty) return 0;
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  final result = await repo.getFollowerIds(merchantId);
  return result.fold((_) => 0, (ids) => ids.length);
});
