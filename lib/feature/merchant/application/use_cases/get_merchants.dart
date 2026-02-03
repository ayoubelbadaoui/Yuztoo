import '../../domain/entities/merchant.dart';
import '../../domain/merchant_failure.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

/// Use case for getting all active merchants, optionally filtered by city.
/// 
/// This use case:
/// - Fetches active merchants from repository
/// - Optionally filters by city if provided
/// - Returns list of merchants (empty list if none found)
class GetMerchants {
  const GetMerchants(this._repository);

  final MerchantRepository _repository;

  Future<Result<List<Merchant>>> call({String? city}) async {
    // Get merchants from repository
    final result = await _repository.getMerchants(city: city);

    // Convert any failures to MerchantFailure if needed
    return result.fold(
      (failure) => Left<MerchantFailure, List<Merchant>>(
        failure is MerchantFailure
            ? failure
            : MerchantUnexpectedFailure(
                message: failure.message,
                cause: failure.cause,
                stackTrace: failure.stackTrace,
              ),
      ),
      (merchants) => Right<MerchantFailure, List<Merchant>>(merchants),
    );
  }
}

