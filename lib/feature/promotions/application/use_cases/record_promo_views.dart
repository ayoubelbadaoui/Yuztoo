import '../../domain/repositories/promotion_repository.dart';

/// Records that a client viewed a set of promotions (increments view_count).
/// Best-effort — never throws.
class RecordPromoViews {
  const RecordPromoViews(this._repository);
  final PromotionRepository _repository;

  Future<void> call({
    required String merchantId,
    required List<String> promotionIds,
  }) =>
      _repository.recordViews(
        merchantId: merchantId,
        promotionIds: promotionIds,
      );
}
