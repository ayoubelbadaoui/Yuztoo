import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../loyalty/domain/loyalty_passage_program_policy.dart';
import '../../domain/entities/loyalty_program_config.dart';
import '../../domain/entities/merchant.dart';
import '../../domain/repositories/merchant_repository.dart';

/// Update rappels toggles and keep [LoyaltyProgramConfig.passageValidation] in sync.
class UpdateRappelsSettings {
  const UpdateRappelsSettings(this._repository);

  final MerchantRepository _repository;

  Future<Result<Merchant>> call({
    required String merchantId,
    required bool rappelsAutoClientValidation,
    required bool rappelsAutoPassageValidation,
  }) async {
    final merchantResult = await _repository.getMerchantById(merchantId);
    return merchantResult.fold(
      (failure) => Left<AppFailure, Merchant>(failure),
      (merchant) async {
        if (merchant == null) {
          return const Left<AppFailure, Merchant>(
            UnexpectedFailure(message: 'Profil commerçant introuvable'),
          );
        }

        final live = merchantLiveLoyaltyProgram(merchant);
        final syncedProgram = live.copyWith(
          passageValidation: rappelsAutoPassageValidation
              ? LoyaltyPassageValidation.automatic
              : LoyaltyPassageValidation.manual,
        );

        return _repository.updateMerchant(
          merchantId: merchantId,
          rappelsAutoClientValidation: rappelsAutoClientValidation,
          rappelsAutoPassageValidation: rappelsAutoPassageValidation,
          loyaltyProgram: syncedProgram,
        );
      },
    );
  }
}
