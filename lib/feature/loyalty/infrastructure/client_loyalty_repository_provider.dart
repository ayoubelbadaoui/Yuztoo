import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/client_loyalty_repository.dart';
import 'firestore_client_loyalty_repository.dart';

final clientLoyaltyRepositoryProvider = Provider<ClientLoyaltyRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreClientLoyaltyRepository(firestore: firestore);
});
