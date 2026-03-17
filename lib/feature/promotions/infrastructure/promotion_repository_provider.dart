import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/infrastructure/firebase_providers.dart';
import '../../storage/infrastructure/storage_repository_provider.dart';
import '../domain/repositories/promotion_repository.dart';
import 'firestore_promotion_repository.dart';

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final storage = ref.watch(storageRepositoryProvider);
  return FirestorePromotionRepository(
    firestore: firestore,
    storageRepository: storage,
  );
});
