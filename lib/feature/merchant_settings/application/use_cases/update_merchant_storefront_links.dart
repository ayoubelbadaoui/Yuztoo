import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/merchant_storefront_link.dart';
import '../../../merchant/domain/repositories/merchant_repository.dart';

/// Persists custom vitrine links on the merchant Firestore document.
class UpdateMerchantStorefrontLinks {
  const UpdateMerchantStorefrontLinks(this._repository);

  final MerchantRepository _repository;

  Future<Result<Unit>> call({
    required String merchantId,
    required List<MerchantStorefrontLink> links,
  }) async {
    final sanitized = links
        .map(
          (l) => MerchantStorefrontLink(
            label: l.label.trim(),
            value: l.value.trim(),
          ),
        )
        .where((l) => l.isValid)
        .toList(growable: false);

    final result = await _repository.updateMerchant(
      merchantId: merchantId,
      storefrontLinks: sanitized,
    );
    return result.fold(
      (failure) => Left<AppFailure, Unit>(failure),
      (_) => const Right<AppFailure, Unit>(unit),
    );
  }
}
