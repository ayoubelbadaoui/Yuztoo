import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../../auth/core/application/providers.dart' show currentUserIdProvider;
import '../domain/entities/restons_proches_profile.dart';
import '../domain/repositories/restons_proches_repository.dart';
import '../infrastructure/firestore_restons_proches_repository.dart';

final restonsProchesRepositoryProvider =
    Provider<RestonsProchesRepository>((ref) {
  return FirestoreRestonsProchesRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

/// Public Restons proches profile (Pascal page).
final yuztooContactProvider =
    FutureProvider.autoDispose<RestonsProchesProfile?>((ref) async {
  final result = await ref.watch(restonsProchesRepositoryProvider).getProfile();
  return result.fold((failure) => throw failure, (profile) => profile);
});

/// True when the signed-in user owns the YuzToo official merchant page.
final canEditRestonsProchesProvider = Provider.autoDispose<bool>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) return false;
  final profile = ref.watch(yuztooContactProvider).valueOrNull;
  if (profile == null) return false;
  return profile.ownerUid == uid;
});
