import '../../../../core/domain/core/result.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/repositories/promotion_repository.dart';

/// Updates a promotion (e.g. isOnline toggle, or image replacement).
class UpdatePromotion {
  const UpdatePromotion(this._repository);

  final PromotionRepository _repository;

  Future<Result<Promotion>> call(
    Promotion promotion, {
    String? imageFilePath,
  }) =>
      _repository.update(promotion, imageFilePath: imageFilePath);
}
