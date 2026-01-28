import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/user_repository.dart';
import '../../../../../core/infrastructure/firebase_providers.dart';
import 'firebase_user_repository.dart';
import 'role_cache_service.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirebaseUserRepository(firestore: firestore);
});

final roleCacheServiceProvider = Provider<RoleCacheService>((ref) {
  return RoleCacheService();
});

