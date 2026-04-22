import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/i_merchant_crm_repository.dart';
import 'firestore_merchant_crm_repository.dart';

final merchantCrmRepositoryProvider = Provider<IMerchantCrmRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreMerchantCrmRepository(firestore: firestore);
});
