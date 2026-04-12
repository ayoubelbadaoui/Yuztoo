import '../../domain/repositories/followed_merchants_repository.dart';
import '../../../../core/domain/core/result.dart';

/// Ensures the merchant is followed, then persists [heartLevel].
class EnsureFollowedAndSetHeartLevel {
  const EnsureFollowedAndSetHeartLevel(this._repository);

  final FollowedMerchantsRepository _repository;

  Future<Result<Unit>> call({
    required String userId,
    required String merchantId,
    required int heartLevel,
  }) async {
    final addResult = await _repository.add(userId, merchantId);
    if (addResult.isLeft) return addResult;
    return _repository.setHeartLevel(userId, merchantId, heartLevel);
  }
}
