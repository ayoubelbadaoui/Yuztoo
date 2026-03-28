import '../../../../core/domain/core/result.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/repositories/promotion_repository.dart';

/// Updates a promotion (e.g. isOnline toggle).
class UpdatePromotion {
  const UpdatePromotion(this._repository);

  final PromotionRepository _repository;

  Future<Result<Promotion>> call(Promotion promotion) =>
      _repository.update(promotion);
}
