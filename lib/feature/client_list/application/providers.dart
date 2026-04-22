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
