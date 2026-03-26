import '../../../../../core/domain/core/result.dart';
import '../../domain/repositories/user_repository.dart';

class ConsumeForceMerchantNextLogin {
  const ConsumeForceMerchantNextLogin(this._repository);

  final UserRepository _repository;

  Future<Result<bool>> call(String uid) =>
      _repository.consumeForceMerchantNextLogin(uid);
}

