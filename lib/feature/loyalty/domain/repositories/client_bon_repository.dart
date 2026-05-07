import '../entities/client_bon.dart';

/// Read-only access to a client's persisted loyalty bons. All writes
/// (issuance, redemption, notification markers) happen server-side via
/// Cloud Functions; client code never mutates these docs directly.
abstract class ClientBonRepository {
  /// Live stream of every bon this client owns. The caller filters by
  /// status (active / expiring / expired / redeemed) — the repo
  /// returns the raw list so a future "historique" view can show
  /// redeemed/expired entries from the same source.
  Stream<List<ClientBon>> watchAll(String clientId);
}
