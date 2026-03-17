import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/storage_repository.dart';
import 'firebase_storage_repository.dart';

/// Provider for StorageRepository implementation.
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return FirebaseStorageRepository(storage: storage);
});
