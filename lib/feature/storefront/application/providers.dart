import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/entities/storefront.dart';
import '../domain/entities/business_hours.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';

part 'providers.part.dart';

/// Provider for storefront data — strictly Firestore-driven.
///
/// [autoDispose] so leaving the vitrine (and any screen that watched this) can
/// drop cached [AsyncData]; returning to the tab or resuming the app refetches
/// fresh merchant data instead of showing a stale snapshot.
final storefrontProvider = FutureProvider.autoDispose<Storefront?>((ref) async {
  final authState = ref.watch(auth_providers.authStateProvider);

  if (authState is! Authenticated) {
    return null;
  }

  final userId = authState.user.id;
  final firestore = ref.read(firebaseFirestoreProvider);
  final merchantRepo = ref.read(merchantRepositoryProvider);

  final userDoc = await firestore.collection('users').doc(userId).get();
  final userData = userDoc.data();
  final merchantId = (userData?['merchant_id'] as String?)?.trim();
  if (merchantId == null || merchantId.isEmpty) {
    return null;
  }

  final merchantResult = await merchantRepo.getMerchantById(merchantId);
  return merchantResult.fold(
    (failure) => throw Exception(
      failure.message.isNotEmpty
          ? failure.message
          : 'Impossible de charger la boutique.',
    ),
    (merchant) => merchant == null ? null : _storefrontFromMerchant(merchant),
  );
});

/// Provider for selected tab in storefront navigation
final storefrontTabProvider = StateProvider<String>((ref) => 'actualite');

/// Provider for business hours data (stateful)
final businessHoursProvider =
    StateNotifierProvider<BusinessHoursNotifier, BusinessHours>((ref) {
  return BusinessHoursNotifier(_initialBusinessHours());
});
