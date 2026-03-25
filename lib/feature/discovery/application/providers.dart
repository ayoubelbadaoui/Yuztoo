import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';

/// Merchants list for Découvrir (Recommandations). Loads real data from Firestore.
final discoveryMerchantsProvider = FutureProvider<List<Merchant>>((ref) async {
  final repo = ref.watch(merchantRepositoryProvider);
  final result = await repo.listMerchants(limit: 50);
  return result.fold(
    (failure) => <Merchant>[],
    (list) => list,
  );
});
