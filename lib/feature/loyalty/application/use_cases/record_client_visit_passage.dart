import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/loyalty_passage_program_policy.dart';
import '../../domain/repositories/client_loyalty_repository.dart';

/// Enregistre un **passage seul** (sans programme fidélité actif).
///
/// Incrémente `validated_passages` sur `loyalty_clients` pour alimenter la
/// gratification client (paliers Nouveau / Habitué / VIP) et les stats CRM.
class RecordClientVisitPassage {
  const RecordClientVisitPassage(this._repository);

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

    return _repository.applyPassageDeltas(
      merchantId: merchant.id,
      clientUid: clientUid,
      validatedPassagesDelta: 1,
      enforcePassageCooldown: merchantPassageCooldownEnabled(merchant),
    );
  }
}
