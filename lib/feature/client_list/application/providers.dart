import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/merchant_client_row.dart';
import '../infrastructure/merchant_crm_repository_provider.dart';

/// Live stream of all clients for [merchantId].
final merchantClientsProvider = StreamProvider.autoDispose
    .family<List<MerchantClientRow>, String>((ref, merchantId) {
  if (merchantId.isEmpty) {
    return Stream<List<MerchantClientRow>>.value(<MerchantClientRow>[]);
  }
  final repo = ref.watch(merchantCrmRepositoryProvider);
  return repo.watchClients(merchantId);
});

/// Use-case-style provider for setting/clearing the merchant's manual segment
/// label on a specific client. Exposes the repo method as a typed function so
/// UI code never imports the repo interface directly.
final setClientManualSegmentProvider =
    Provider<Future<void> Function({
  required String merchantId,
  required String clientUid,
  required ClientSegment? segment,
})>((ref) {
  final repo = ref.watch(merchantCrmRepositoryProvider);
  return ({
    required String merchantId,
    required String clientUid,
    required ClientSegment? segment,
  }) =>
      repo.setClientManualSegment(
        merchantId: merchantId,
        clientUid: clientUid,
        segment: segment,
      );
});
