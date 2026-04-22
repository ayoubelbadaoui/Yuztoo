import '../entities/merchant_client_row.dart';

/// Repository interface for merchant CRM — list of clients.
/// Domain layer: no Firestore types.
abstract class IMerchantCrmRepository {
  /// Live stream of all clients who follow [merchantId], ordered by follow date desc.
  Stream<List<MerchantClientRow>> watchClients(String merchantId);
}
