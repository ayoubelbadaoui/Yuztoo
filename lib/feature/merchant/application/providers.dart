import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/merchant_repository_provider.dart';
import '../infrastructure/merchant_profile_cache_service.dart';
import 'use_cases/create_merchant_use_case.dart';
import 'use_cases/complete_merchant_onboarding.dart';
import 'use_cases/update_storefront.dart';
import 'use_cases/update_rappels_settings.dart';
import '../../storage/application/providers.dart' as storage_providers;

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

