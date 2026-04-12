import '../../../../core/domain/core/result.dart';
import '../entities/client_merchant_loyalty_progress.dart';
import '../entities/loyalty_pending_client_row.dart';

/// Persistance progression fidélité côté client.
abstract class ClientLoyaltyRepository {
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
    String merchantId,
    String clientUid,
  );

  /// Clients avec `pending_passages > 0` (pour l’espace marchand / Rappels).
  Stream<List<LoyaltyPendingClientRow>> watchPendingLoyaltyClients(
    String merchantId,
  );

  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    int pendingPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
  });
}
