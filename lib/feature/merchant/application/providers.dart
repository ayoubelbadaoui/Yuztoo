import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../infrastructure/merchant_repository_provider.dart';
import '../infrastructure/merchant_profile_cache_service.dart';
import '../domain/entities/merchant.dart';
import 'use_cases/create_merchant_use_case.dart';
import 'use_cases/complete_merchant_onboarding.dart';
import 'use_cases/update_storefront.dart';
import 'use_cases/update_rappels_settings.dart';
import '../../storage/application/providers.dart' as storage_providers;

export '../../auth/core/application/providers.dart'
    show
        authStateProvider,
        getUserProfileBasicsProvider,
        getUserCityProvider;
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

/// Provider for MerchantProfileCacheService (demo mode - local storage).
final merchantProfileCacheServiceProvider =
    Provider<MerchantProfileCacheService>((ref) {
  return MerchantProfileCacheService();
});

/// Signed-in merchant profile (from `users.merchant_id` + [MerchantRepository.getMerchantById]).
///
/// `null` when not authenticated, no `merchant_id`, or merchant doc missing.
final currentMerchantForOwnerProvider =
    FutureProvider.autoDispose<Merchant?>((ref) async {
  final authState = ref.watch(auth_providers.authStateProvider);
  if (authState is! Authenticated) {
    return null;
  }
  final userId = authState.user.id;
  final firestore = ref.watch(firebaseFirestoreProvider);
  final merchantRepo = ref.watch(merchantRepositoryProvider);

  final userDoc = await firestore.collection('users').doc(userId).get();
  final merchantId = (userDoc.data()?['merchant_id'] as String?)?.trim();
  if (merchantId == null || merchantId.isEmpty) {
    return null;
  }

  final result = await merchantRepo.getMerchantById(merchantId);
  return result.fold((_) => null, (m) => m);
});
