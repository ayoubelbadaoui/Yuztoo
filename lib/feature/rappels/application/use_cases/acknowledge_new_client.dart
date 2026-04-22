import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/i_rappels_pending_client_repository.dart';

/// Acknowledges (dismisses) a new client from the merchant's pending list.
class AcknowledgeNewClient {
  const AcknowledgeNewClient(this._repository);

  final IRappelsPendingClientRepository _repository;

  Future<Result<Unit>> call({
    required String merchantId,
    required String clientUid,
  }) =>
      _repository.acknowledge(merchantId, clientUid);
}
