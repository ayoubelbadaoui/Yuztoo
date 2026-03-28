import '../../../../core/domain/core/result.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/repositories/promotion_repository.dart';

/// Lists all promotions for a merchant.
class ListPromotionsByMerchant {
  const ListPromotionsByMerchant(this._repository);

  final PromotionRepository _repository;

  Future<Result<List<Promotion>>> call(String merchantId) =>
      _repository.listByMerchantId(merchantId);
}
