import '../entities/merchant_client_row.dart';

/// Repository interface for merchant CRM — list of clients.
/// Domain layer: no Firestore types.
abstract class IMerchantCrmRepository {
  /// Live stream of all clients who follow [merchantId], ordered by follow date desc.
  Stream<List<MerchantClientRow>> watchClients(String merchantId);

  /// Set or clear the merchant's manual segment label for a specific client.
  ///
  /// Pass [segment] = null to remove the manual label and fall back to the
  /// auto-computed segment. Writes to
  /// `merchants/{merchantId}/clients/{clientUid}.manual_segment`.
  Future<void> setClientManualSegment({
    required String merchantId,
    required String clientUid,
    required ClientSegment? segment,
  });
}
