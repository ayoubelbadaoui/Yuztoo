import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/merchant_repository.dart';
import '../../../../core/infrastructure/firebase_providers.dart';
import 'firestore_merchant_repository.dart';

/// Provider for MerchantRepository implementation.
final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreMerchantRepository(firestore: firestore);
});

