import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/client_bon_repository.dart';
import 'firestore_client_bon_repository.dart';

final clientBonRepositoryProvider = Provider<ClientBonRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreClientBonRepository(firestore: firestore);
});
