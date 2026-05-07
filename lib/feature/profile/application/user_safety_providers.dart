import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' show currentUserIdProvider;
import '../domain/repositories/user_safety_repository.dart';
import '../infrastructure/firestore_user_safety_repository.dart';

/// Single-instance repository — Firestore is the only backing store and
/// instantiation is cheap.
final userSafetyRepositoryProvider = Provider<UserSafetyRepository>((ref) {
  return FirestoreUserSafetyRepository(firestore: FirebaseFirestore.instance);
});

/// Live set of merchant IDs blocked by the connected user. Consumers
/// (carnet, recommendations, notifications UI) should filter on this so
/// blocked merchants vanish from every feed in real time after a block.
///
/// Returns an empty set when no user is signed in.
final blockedMerchantIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    return Stream<Set<String>>.value(const <String>{});
  }
  return ref.watch(userSafetyRepositoryProvider).watchBlockedMerchantIds(uid);
});
