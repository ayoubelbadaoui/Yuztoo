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

  /// Get followed merchants with saved heart level (1 or 2).
  Future<Result<Map<String, int>>> getFollowedHeartLevels(String userId);

  /// Save heart level for a followed merchant.
  Future<Result<Unit>> setHeartLevel(String userId, String merchantId, int heartLevel);

  /// Count how many users follow each merchant id.
  Future<Result<Map<String, int>>> getFollowersCounts(List<String> merchantIds);
}
