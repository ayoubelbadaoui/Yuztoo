import '../../domain/entities/merchant.dart';
import '../../domain/merchant_failure.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

/// Use case for getting a merchant by merchant ID.
/// 
/// This use case:
/// - Validates merchant ID
/// - Fetches merchant document from repository
/// - Returns merchant if found, null if not found
class GetMerchantById {
  const GetMerchantById(this._repository);

  final MerchantRepository _repository;

  Future<Result<Merchant?>> call(String merchantId) async {
    // Validate merchant ID
    if (merchantId.isEmpty) {
      return const Right<MerchantFailure, Merchant?>(null);
    }

    // Get merchant from repository
    final result = await _repository.getMerchantById(merchantId);

    // Convert any failures to MerchantFailure if needed
    return result.fold(
      (failure) => Left<MerchantFailure, Merchant?>(
        failure is MerchantFailure
            ? failure
            : MerchantUnexpectedFailure(
                message: failure.message,
                cause: failure.cause,
                stackTrace: failure.stackTrace,
              ),
      ),
      (merchant) => Right<MerchantFailure, Merchant?>(merchant),
    );
  }
}

