import '../../../../core/domain/core/result.dart';
import '../entities/pending_client_row.dart';

/// Repository for new clients awaiting merchant acknowledgement.
///
/// Firestore: `merchants/{merchantId}/pending_clients/{clientUid}`
/// with { followed_at: timestamp }.
abstract class IRappelsPendingClientRepository {
  /// Stream of clients not yet acknowledged by the merchant.
  Stream<List<PendingClientRow>> watchPendingClients(String merchantId);

  /// Acknowledge (dismiss) a pending client — removes the doc.
  Future<Result<Unit>> acknowledge(String merchantId, String clientUid);
}
