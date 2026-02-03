import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/merchant_repository_provider.dart';
import 'use_cases/create_merchant_use_case.dart';
import 'use_cases/complete_merchant_onboarding.dart';
import 'use_cases/get_merchants.dart';
import 'use_cases/get_merchant_by_id.dart';

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

/// Provider for GetMerchants use case.
final getMerchantsProvider = Provider<GetMerchants>((ref) {
  final repository = ref.watch(merchantRepositoryProvider);
  return GetMerchants(repository);
});

/// Provider for GetMerchantById use case.
final getMerchantByIdProvider = Provider<GetMerchantById>((ref) {
  final repository = ref.watch(merchantRepositoryProvider);
  return GetMerchantById(repository);
});

