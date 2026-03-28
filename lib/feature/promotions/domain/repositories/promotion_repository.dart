import '../../../../core/domain/core/result.dart';
import '../entities/promotion.dart';

/// Repository interface for promotion operations in Firestore.
/// Promotions are stored as subcollection: merchants/{merchantId}/promotions/{promoId}
abstract class PromotionRepository {
  /// Create a promotion for a merchant.
  Future<Result<Promotion>> create({
    required String merchantId,
    required Promotion promotion,
    String? imageFilePath,
  });

  /// List all promotions for a merchant.
  Future<Result<List<Promotion>>> listByMerchantId(String merchantId);

  /// Update a promotion (e.g. isOnline).
  Future<Result<Promotion>> update(Promotion promotion);

  /// Delete a promotion.
  Future<Result<Unit>> delete({
    required String merchantId,
    required String promotionId,
  });
}
