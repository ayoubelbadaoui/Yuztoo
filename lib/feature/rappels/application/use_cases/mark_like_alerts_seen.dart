import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/i_merchant_like_alerts_repository.dart';

/// Marks all current like alerts as seen for a merchant (watermark update).
class MarkLikeAlertsSeen {
  const MarkLikeAlertsSeen(this._repository);

  final IMerchantLikeAlertsRepository _repository;

  Future<Result<Unit>> call({required String merchantId}) =>
      _repository.markAllSeen(merchantId);
}
