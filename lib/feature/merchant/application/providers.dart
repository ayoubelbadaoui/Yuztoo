import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../../../core/infrastructure/logger_service.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../infrastructure/merchant_repository_provider.dart';
import '../infrastructure/merchant_profile_cache_service.dart';
import '../domain/entities/merchant.dart';
import '../../client_notification/infrastructure/client_notification_repository_provider.dart';
import '../../loyalty/infrastructure/client_loyalty_repository_provider.dart';
import 'use_cases/create_merchant_use_case.dart';
import 'use_cases/complete_merchant_onboarding.dart';
import 'use_cases/merchant_record_client_passage.dart';
import 'use_cases/update_gratification_config.dart';
import 'use_cases/update_storefront.dart';
import 'use_cases/update_rappels_settings.dart';
import '../../storage/application/providers.dart' as storage_providers;

export '../../auth/core/application/providers.dart'
    show authStateProvider, getUserProfileBasicsProvider, getUserCityProvider;
export '../../auth/core/application/state/auth_state.dart' show Authenticated;
export '../../storefront/application/providers.dart' show storefrontProvider;
export '../../storage/application/providers.dart'
    show uploadLogoProvider, uploadBannerProvider, deleteStorageImageProvider;

/// Provider for CreateMerchantUseCase.
final createMerchantUseCaseProvider = Provider<CreateMerchantUseCase>((ref) {
  final repository = ref.watch(merchantRepositoryProvider);
  return CreateMerchantUseCase(repository);
});

/// Provider for CompleteMerchantOnboarding use case.
final completeMerchantOnboardingProvider =
    Provider<CompleteMerchantOnboarding>((ref) {
  final repository = ref.watch(merchantRepositoryProvider);
  return CompleteMerchantOnboarding(repository);
});

/// Provider for UpdateStorefront use case.
final updateStorefrontProvider = Provider<UpdateStorefront>((ref) {
  final repository = ref.watch(merchantRepositoryProvider);
  final uploadLogo = ref.watch(storage_providers.uploadLogoProvider);
  final uploadBanner = ref.watch(storage_providers.uploadBannerProvider);
  return UpdateStorefront(
    merchantRepository: repository,
    uploadLogo: uploadLogo,
    uploadBanner: uploadBanner,
  );
});

/// Provider for UpdateRappelsSettings use case.
final updateRappelsSettingsProvider = Provider<UpdateRappelsSettings>((ref) {
  final repository = ref.watch(merchantRepositoryProvider);
  return UpdateRappelsSettings(repository);
});

/// Provider for MerchantRecordClientPassage use case.
/// Called from the merchant BLE/QR scan screen when validating a client's passage.
final merchantRecordClientPassageProvider =
    Provider<MerchantRecordClientPassage>((ref) {
  return MerchantRecordClientPassage(
    ref.watch(clientLoyaltyRepositoryProvider),
    ref.watch(clientNotificationRepositoryProvider),
  );
});

/// Provider for UpdateGratificationConfig use case.
final updateGratificationConfigProvider =
    Provider<UpdateGratificationConfig>((ref) {
  final repository = ref.watch(merchantRepositoryProvider);
  return UpdateGratificationConfig(repository);
});

/// Provider for MerchantProfileCacheService (demo mode - local storage).
final merchantProfileCacheServiceProvider =
    Provider<MerchantProfileCacheService>((ref) {
  return MerchantProfileCacheService();
});

/// The store the signed-in merchant is currently managing.
///
/// Live from `users/{uid}.merchant_id`; switching store rewrites that field and
/// every merchant screen follows. When the field is missing (interrupted
/// onboarding writes) the oldest store owned via `owner_uid` is used.
final activeMerchantIdProvider = StreamProvider<String?>((ref) {
  final authState = ref.watch(auth_providers.authStateProvider);
  if (authState is! Authenticated) return Stream<String?>.value(null);
  final userId = authState.user.id;
  final firestore = ref.watch(firebaseFirestoreProvider);
  final merchantRepo = ref.watch(merchantRepositoryProvider);

  return firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .asyncMap<String?>((doc) async {
    final linked = (doc.data()?['merchant_id'] as String?)?.trim();
    if (linked != null && linked.isNotEmpty) return linked;
    final owned = await merchantRepo.getMerchantsByOwnerUid(userId);
    return owned.fold((_) => null, (l) => l.isEmpty ? null : l.first.id);
  }).distinct();
});

/// Every store the signed-in user owns (oldest first).
final ownedMerchantsProvider =
    FutureProvider.autoDispose<List<Merchant>>((ref) async {
  final authState = ref.watch(auth_providers.authStateProvider);
  if (authState is! Authenticated) return const <Merchant>[];
  final result = await ref
      .watch(merchantRepositoryProvider)
      .getMerchantsByOwnerUid(authState.user.id);
  return result.fold((_) => const <Merchant>[], (l) => l);
});

/// Signed-in merchant profile for the active store ([activeMerchantIdProvider]).
///
/// `null` when not authenticated or no store is linked.
///
/// Network/Firestore throws are caught so screens (e.g. E-Fidélité) do not
/// surface [AsyncError] red states on transient failures — same as a missing
/// merchant for UX purposes; logs retain diagnostics.
final currentMerchantForOwnerProvider =
    FutureProvider.autoDispose<Merchant?>((ref) async {
  // Avoid aggressive refetch/dispose churn on Android when navigating
  // (e.g. E-Fidélité) while still invalidating explicitly after saves.
  // Only cache successes: a failed load must not stick as "no store" for the
  // whole session — closing the link lets the next visit refetch.
  final keepAlive = ref.keepAlive();

  final merchantRepo = ref.watch(merchantRepositoryProvider);
  String? merchantId;
  try {
    merchantId = await ref.watch(activeMerchantIdProvider.future);
    if (merchantId == null || merchantId.isEmpty) return null;

    final result = await merchantRepo.getMerchantById(merchantId);
    return result.fold<Merchant?>((_) {
      keepAlive.close();
      return null;
    }, (m) => m);
  } catch (e, st) {
    keepAlive.close();
    LoggerService.logError(
      'currentMerchantForOwnerProvider: load failed',
      error: e,
      stackTrace: st,
      context: <String, dynamic>{'merchantId': merchantId},
    );
    return null;
  }
});

/// Whether the signed-in user owns a merchant (pro) profile — used for the
/// client-home "switch to merchant" affordance even when `roles.merchant` is
/// missing from a stale auth snapshot.
final hasLinkedMerchantAccountProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final authState = ref.watch(auth_providers.authStateProvider);
  if (authState is! Authenticated) return false;

  final user = authState.user;
  if (user.roles?['merchant'] == true) return true;

  final merchant = await ref.watch(currentMerchantForOwnerProvider.future);
  if (merchant != null) return true;

  final merchantRepo = ref.watch(merchantRepositoryProvider);
  final legacy = await merchantRepo.getMerchantById(user.id);
  return legacy.fold((_) => false, (m) => m != null);
});
