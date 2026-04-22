import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/infrastructure/firebase_providers.dart';
import '../../rappels/infrastructure/rappels_pending_client_repository_provider.dart';
import '../domain/repositories/followed_merchants_repository.dart';
import 'firestore_followed_merchants_repository.dart';

final followedMerchantsRepositoryProvider = Provider<FollowedMerchantsRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final pendingClientRepo = ref.watch(rappelsPendingClientRepositoryProvider);
  return FirestoreFollowedMerchantsRepository(
    firestore: firestore,
    pendingClientRepo: pendingClientRepo,
  );
});
