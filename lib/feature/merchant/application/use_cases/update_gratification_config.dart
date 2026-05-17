import '../../../../core/domain/core/result.dart';
import '../../domain/entities/client_gratification_config.dart';
import '../../domain/repositories/merchant_repository.dart';

class UpdateGratificationConfig {
  const UpdateGratificationConfig(this._repository);

  final MerchantRepository _repository;

  Future<Result<void>> call({
    required String merchantId,
    required ClientGratificationConfig config,
  }) =>
      _repository.updateGratificationConfig(
        merchantId: merchantId,
        config: config,
      );
}
