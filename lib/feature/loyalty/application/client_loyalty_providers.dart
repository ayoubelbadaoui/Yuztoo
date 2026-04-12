import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart';
import '../infrastructure/client_loyalty_repository_provider.dart';
import 'use_cases/record_loyalty_passage.dart';
import 'use_cases/validate_pending_loyalty_passage.dart';
import '../domain/entities/loyalty_pending_client_row.dart';

final recordLoyaltyPassageProvider = Provider<RecordLoyaltyPassage>((ref) {
  return RecordLoyaltyPassage(ref.watch(clientLoyaltyRepositoryProvider));
});

final validatePendingLoyaltyPassageProvider =
    Provider<ValidatePendingLoyaltyPassage>((ref) {
  return ValidatePendingLoyaltyPassage(ref.watch(clientLoyaltyRepositoryProvider));
});

/// Progression fidélité du client connecté pour un commerce.
final clientLoyaltyProgressForMerchantProvider =
    StreamProvider.autoDispose.family<ClientMerchantLoyaltyProgress, String>(
  (ref, merchantId) {
    final auth = ref.watch(authStateProvider);
    if (auth is! Authenticated) {
      return Stream<ClientMerchantLoyaltyProgress>.value(
        const ClientMerchantLoyaltyProgress.empty(),
      );
    }
    final repo = ref.watch(clientLoyaltyRepositoryProvider);
    return repo.watchProgress(merchantId, auth.user.id);
  },
);

/// Passages en attente (validation manuelle) pour un commerce.
final pendingLoyaltyClientsForMerchantProvider = StreamProvider.autoDispose
    .family<List<LoyaltyPendingClientRow>, String>(
  (ref, merchantId) {
    if (merchantId.isEmpty) {
      return Stream<List<LoyaltyPendingClientRow>>.value(
        <LoyaltyPendingClientRow>[],
      );
    }
    final repo = ref.watch(clientLoyaltyRepositoryProvider);
    return repo.watchPendingLoyaltyClients(merchantId);
  },
);
