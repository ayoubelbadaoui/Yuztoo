import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/active_validation_repository.dart';
import 'firestore_active_validation_repository.dart';

final activeValidationRepositoryProvider =
    Provider<ActiveValidationRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreActiveValidationRepository(firestore: firestore);
});
