import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../followed_merchants/domain/repositories/followed_merchants_repository.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/failures/ble_passage_failure.dart';

/// Returns [Right] when the client already follows [merchant].
/// Returns [Left] with [FollowRequiredFailure] when not following.
class EnsureClientFollowsMerchant {
  const EnsureClientFollowsMerchant(this._followedRepo);

  final FollowedMerchantsRepository _followedRepo;

  Future<Result<void>> call({
    required String clientUid,
    required Merchant merchant,
  }) async {
    if (clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Utilisateur non connecté'),
      );
    }
    final following = await _followedRepo.isFollowing(clientUid, merchant.id);
    return following.fold(
      (f) => Left<AppFailure, void>(f),
      (isFollowing) {
        if (isFollowing) {
          return const Right<AppFailure, void>(null);
        }
        final name = merchant.displayName?.trim().isNotEmpty == true
            ? merchant.displayName!.trim()
            : merchant.name;
        return Left<AppFailure, void>(
          FollowRequiredFailure(
            merchantId: merchant.id,
            merchantDisplayName: name,
          ),
        );
      },
    );
  }
}
