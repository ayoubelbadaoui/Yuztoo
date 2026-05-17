import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../client_home/application/providers.dart'
    show clientHomeFeedProvider;
import '../../discovery/application/providers.dart'
    show invalidateDiscoveryCatalog;
import '../../merchant/application/providers.dart' as merchant_providers;

/// Invalidates profile-related Riverpod caches and reloads [AuthUser] from
/// Firebase + Firestore so headers, avatars, and names update without restart.
Future<void> refreshUserProfileCache(
  Ref ref, {
  required String uid,
  bool? isMerchant,
  bool cityChanged = false,
}) async {
  ref.invalidate(auth_providers.userProfileBasicsProvider(uid));
  ref.invalidate(auth_providers.connectedCitiesProvider(uid));

  final merchant = isMerchant ??
      (ref.read(auth_providers.authControllerProvider) is Authenticated &&
          (ref.read(auth_providers.authControllerProvider) as Authenticated)
              .user
              .isMerchant);

  if (merchant) {
    ref.invalidate(merchant_providers.storefrontProvider);
    ref.invalidate(merchant_providers.currentMerchantForOwnerProvider);
    if (cityChanged) {
      invalidateDiscoveryCatalog(ref);
    }
  } else {
    ref.invalidate(clientHomeFeedProvider);
  }

  await ref
      .read(auth_providers.authControllerProvider.notifier)
      .reloadProfile();
}
