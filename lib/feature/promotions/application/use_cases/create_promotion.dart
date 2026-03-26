import '../../../../core/domain/core/result.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/repositories/promotion_repository.dart';

/// Creates a promotion for the given merchant (uploads image if provided, then saves to Firestore).
class CreatePromotion {
  const CreatePromotion(this._repository);

  final PromotionRepository _repository;

  Future<Result<Promotion>> call({
    required String merchantId,
    required Promotion promotion,
    String? imageFilePath,
  }) =>
      _repository.create(
        merchantId: merchantId,
        promotion: promotion,
        imageFilePath: imageFilePath,
      );
}
