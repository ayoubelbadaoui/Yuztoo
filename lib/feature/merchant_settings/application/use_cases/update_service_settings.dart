import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/repositories/merchant_repository.dart';

/// Updates the three active Yuztoo service toggles on the merchant document.
class UpdateServiceSettings {
  const UpdateServiceSettings(this._repository);

  final MerchantRepository _repository;

  Future<Result<Unit>> call({
    required String merchantId,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabled,
  }) async {
    final result = await _repository.updateMerchant(
      merchantId: merchantId,
      notificationsAutoEnabled: notificationsAutoEnabled,
      galerieEnabled: galerieEnabled,
      loyaltyEnabledStandalone: loyaltyEnabled,
    );
    return result.fold(
      (failure) => Left<AppFailure, Unit>(failure),
      (_) => const Right<AppFailure, Unit>(unit),
    );
  }
}
