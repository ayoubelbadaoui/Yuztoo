import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/promotion_repository.dart';

/// Deletes a promotion.
class DeletePromotion {
  const DeletePromotion(this._repository);

  final PromotionRepository _repository;

  Future<Result<Unit>> call({
    required String merchantId,
    required String promotionId,
  }) =>
      _repository.delete(merchantId: merchantId, promotionId: promotionId);
}
