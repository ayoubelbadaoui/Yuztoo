import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/i_rappels_pending_client_repository.dart';
import 'firestore_rappels_pending_client_repository.dart';

final rappelsPendingClientRepositoryProvider =
    Provider<FirestoreRappelsPendingClientRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreRappelsPendingClientRepository(firestore: firestore);
});

/// Typed as interface for use cases.
final rappelsPendingClientRepoInterfaceProvider =
    Provider<IRappelsPendingClientRepository>((ref) {
  return ref.watch(rappelsPendingClientRepositoryProvider);
});
