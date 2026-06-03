import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/client_loyalty_repository.dart';
import 'firestore_client_loyalty_repository.dart';

/// Minimum delay between two validated passages for the same
/// (client, merchant) pair.
///
/// Goals:
///  - Block accidental double-tap on the merchant validation form.
///  - Stop the simplest fraud loop: a client re-scanning a few seconds
///    later to inflate their counter.
///
/// Enforcement is defence-in-depth — this constant is honoured by the
/// Firestore SDK transaction in [FirestoreClientLoyaltyRepository] AND
/// mirrored in `firestore.rules` via `loyaltyClientPassageCooldownPasses`,
/// so a tampered device clock cannot bypass it. Keep both in sync.
const Duration kPassageCooldown = Duration(hours: 1);

final clientLoyaltyRepositoryProvider = Provider<ClientLoyaltyRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreClientLoyaltyRepository(
    firestore: firestore,
    passageCooldown: kPassageCooldown,
  );
});
