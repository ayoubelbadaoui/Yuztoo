import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../../merchant/domain/repositories/merchant_repository.dart';

/// Persists loyalty questionnaire + keeps Rappels passage auto-validation in sync.
class UpdateMerchantLoyaltyProgram {
  const UpdateMerchantLoyaltyProgram(this._repository);

  final MerchantRepository _repository;

  Future<Result<Merchant>> call({
    required String merchantId,
    required LoyaltyProgramConfig config,
  }) {
    final passageAuto =
        config.passageValidation == LoyaltyPassageValidation.automatic;
    return _repository.updateMerchant(
      merchantId: merchantId,
      loyaltyProgram: config,
      rappelsAutoPassageValidation: passageAuto,
    );
  }
}
