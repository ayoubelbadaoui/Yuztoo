import '../../../../core/domain/core/result.dart';
import '../../domain/entities/merchant.dart';
import '../../domain/repositories/merchant_repository.dart';

/// Update rappels toggles (auto client validation, auto passage validation) in Firestore.
class UpdateRappelsSettings {
  const UpdateRappelsSettings(this._repository);

  final MerchantRepository _repository;

  Future<Result<Merchant>> call({
    required String merchantId,
    required bool rappelsAutoClientValidation,
    required bool rappelsAutoPassageValidation,
  }) =>
      _repository.updateMerchant(
        merchantId: merchantId,
        rappelsAutoClientValidation: rappelsAutoClientValidation,
        rappelsAutoPassageValidation: rappelsAutoPassageValidation,
      );
}
