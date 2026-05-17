import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/repositories/client_loyalty_repository.dart';

/// Client requests a boutique visit — always [pending_passages] +1.
///
/// Validation and purchase amount are handled by the merchant (Rappels / BLE),
/// not by the client.
class RecordLoyaltyPassage {
  RecordLoyaltyPassage(this._repository);

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
        UnexpectedFailure(message: 'La fidélité n’est pas activée pour ce commerce'),
      );
    }

    final LoyaltyProgramConfig config = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
    if (!config.programEnabled) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Le programme de fidélité est désactivé'),
      );
    }

    return _repository.applyPassageDeltas(
      merchantId: merchant.id,
      clientUid: clientUid,
      pendingPassagesDelta: 1,
      enrollProgram: config,
    );
  }
}
