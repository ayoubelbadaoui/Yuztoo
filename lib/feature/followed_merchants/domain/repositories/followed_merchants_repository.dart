import '../../../../core/domain/core/result.dart';

/// Repository for client "followed merchants" (Suivre le commerce).
/// Stored in Firestore: users/{userId}/followed_merchants/{merchantId}.
abstract class FollowedMerchantsRepository {
  /// Add a merchant to the user's followed list.
  Future<Result<Unit>> add(String userId, String merchantId);

  /// Remove a merchant from the user's followed list.
  Future<Result<Unit>> remove(String userId, String merchantId);

  /// Get the list of merchant IDs the user follows.
  Future<Result<List<String>>> getFollowedIds(String userId);

  /// Check if the user follows the given merchant.
  Future<Result<bool>> isFollowing(String userId, String merchantId);
}
