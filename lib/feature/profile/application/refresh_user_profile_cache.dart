import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../client_home/application/providers.dart'
    show clientHomeFeedProvider;
import '../../discovery/application/providers.dart'
    show invalidateDiscoveryCatalog, invalidateDiscoveryCatalogWidget;
import '../../merchant/application/providers.dart' as merchant_providers;

Future<void> _refreshUserProfileCacheImpl({
  required void Function(ProviderOrFamily provider) invalidate,
  required T Function<T>(ProviderListenable<T> provider) read,
  required String uid,
  bool? isMerchant,
  bool cityChanged = false,
  required void Function() invalidateDiscovery,
}) async {
  invalidate(auth_providers.userProfileBasicsProvider(uid));
  invalidate(auth_providers.connectedCitiesProvider(uid));

  final merchant = isMerchant ??
      (read(auth_providers.authControllerProvider) is Authenticated &&
          (read(auth_providers.authControllerProvider) as Authenticated)
              .user
              .isMerchant);

  if (merchant) {
    invalidate(merchant_providers.storefrontProvider);
    invalidate(merchant_providers.currentMerchantForOwnerProvider);
    if (cityChanged) {
      invalidateDiscovery();
    }
  } else {
    invalidate(clientHomeFeedProvider);
  }

  await read(auth_providers.authControllerProvider.notifier).reloadProfile();
}

/// Invalidates profile-related Riverpod caches and reloads [AuthUser] from
/// Firebase + Firestore so headers, avatars, and names update without restart.
///
/// Use [refreshUserProfileCacheWidget] from [ConsumerWidget] / [ConsumerState].
Future<void> refreshUserProfileCache(
  Ref ref, {
  required String uid,
  bool? isMerchant,
  bool cityChanged = false,
}) {
  return _refreshUserProfileCacheImpl(
    invalidate: ref.invalidate,
    read: ref.read,
    uid: uid,
    isMerchant: isMerchant,
    cityChanged: cityChanged,
    invalidateDiscovery: () => invalidateDiscoveryCatalog(ref),
  );
}

/// Widget-facing variant — do not cast [WidgetRef] to [Ref] (runtime crash).
Future<void> refreshUserProfileCacheWidget(
  WidgetRef ref, {
  required String uid,
  bool? isMerchant,
  bool cityChanged = false,
}) {
  return _refreshUserProfileCacheImpl(
    invalidate: ref.invalidate,
    read: ref.read,
    uid: uid,
    isMerchant: isMerchant,
    cityChanged: cityChanged,
    invalidateDiscovery: () => invalidateDiscoveryCatalogWidget(ref),
  );
}
