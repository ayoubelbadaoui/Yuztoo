import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/personal_profile_image_cache.dart';
import '../infrastructure/shared_preferences_personal_profile_image_cache.dart';

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
