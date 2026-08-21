import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/repositories/client_loyalty_repository.dart';

/// Marks the welcome bon as claimed (used) at [merchant] for the connected
/// client. Trust-based v1 — the client taps "Utiliser", confirms, and the
/// claim is recorded immediately. The merchant sees the claim in the loyalty
/// history.
///
/// All preconditions are checked here so the UI can rely on a single Result:
///   - non-empty merchantId/clientUid
///   - loyalty enabled at this merchant
///   - merchant has a non-empty welcome gift configured (otherwise the bon
///     would have nothing to award — the UI must not surface it either)
///   - first visit is recorded on claim if missing (first connexion path)
///
/// Idempotency: a second call after the bon is already claimed returns Right
/// with the unchanged progress (no error). This makes double-tap on the
/// "Utiliser" button safe.
class ClaimWelcomeBon {
  ClaimWelcomeBon(this._repository);

  final ClientLoyaltyRepository _repository;

  Future<Result<ClientMerchantLoyaltyProgress>> call({
    required String clientUid,
    required Merchant merchant,
  }) async {
    if (clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Utilisateur non connecté'),
      );
    }
    if (!merchant.loyaltyEnabled) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'La fidélité n’est pas activée pour ce commerce',
        ),
      );
    }

    final LoyaltyProgramConfig config = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
    if (!config.programEnabled) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Le programme de fidélité est désactivé'),
      );
    }

    final welcome = merchant.welcomeGiftDescription?.trim() ?? '';
    if (welcome.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Aucun bon de bienvenue n’est offert par ce commerce',
        ),
      );
    }

    return _repository.claimWelcomeBon(
      merchantId: merchant.id,
      clientUid: clientUid,
    );
  }
}
