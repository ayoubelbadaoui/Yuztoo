import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/user_repository.dart';
import '../../../core/infrastructure/firebase_providers.dart';
import 'firebase_user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirebaseUserRepository(firestore: firestore);
});

