import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/auth_repository.dart';
import '../../../core/infrastructure/firebase_providers.dart';
import 'firebase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirebaseAuthRepository(auth: auth, firestore: firestore);
});
