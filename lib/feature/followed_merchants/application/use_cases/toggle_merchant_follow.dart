import '../../domain/repositories/followed_merchants_repository.dart';
import '../../../../core/domain/core/result.dart';

class ToggleMerchantFollow {
  const ToggleMerchantFollow(this._repository);

  final FollowedMerchantsRepository _repository;

  Future<Result<Unit>> call({
    required String userId,
    required String merchantId,
    required bool currentlyFollowing,
  }) {
    if (currentlyFollowing) {
      return _repository.remove(userId, merchantId);
    }
    return _repository.add(userId, merchantId);
  }
}
