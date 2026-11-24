import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/i_merchant_like_alerts_repository.dart';
import 'firestore_merchant_like_alerts_repository.dart';

final merchantLikeAlertsRepositoryProvider =
    Provider<FirestoreMerchantLikeAlertsRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreMerchantLikeAlertsRepository(firestore: firestore);
});

final merchantLikeAlertsRepoInterfaceProvider =
    Provider<IMerchantLikeAlertsRepository>((ref) {
  return ref.watch(merchantLikeAlertsRepositoryProvider);
});
