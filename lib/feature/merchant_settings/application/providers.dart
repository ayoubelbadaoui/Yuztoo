import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../../merchant/application/providers.dart'
    show activeMerchantIdProvider;
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import 'portable_user_data_export.dart';
import 'use_cases/update_merchant_storefront_links.dart';
import 'use_cases/update_service_settings.dart';

export '../../auth/core/application/providers.dart' show authControllerProvider;
export '../../merchant/application/providers.dart'
    show
        activeMerchantIdProvider,
        currentMerchantForOwnerProvider,
        updateGratificationConfigProvider;

final updateServiceSettingsProvider = Provider<UpdateServiceSettings>((ref) {
  final repo = ref.watch(merchantRepositoryProvider);
  return UpdateServiceSettings(repo);
});

final updateMerchantStorefrontLinksProvider =
    Provider<UpdateMerchantStorefrontLinks>((ref) {
  final repo = ref.watch(merchantRepositoryProvider);
  return UpdateMerchantStorefrontLinks(repo);
});

/// RGPD Art. 20 — portable JSON built from Firestore reads permitted to the user.
final portableUserDataExportProvider = Provider<PortableUserDataExport>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return PortableUserDataExport(firestore);
});

/// Active store id (for writes). Null while loading or when no store is linked.
final currentMerchantIdProvider = Provider<String?>(
  (ref) => ref.watch(activeMerchantIdProvider).valueOrNull,
);
