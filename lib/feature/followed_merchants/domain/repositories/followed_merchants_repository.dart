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

  /// Get mute state for a followed merchant.
  Future<Result<bool>> getMuteState(String userId, String merchantId);

  /// Set mute state for a followed merchant (true = muted, notifications silenced).
  Future<Result<Unit>> setMuteState(String userId, String merchantId, {required bool muted});

  /// Get all merchant IDs that the user has muted.
  Future<Result<Set<String>>> getMutedMerchantIds(String userId);

  /// Count how many users follow each merchant id.
  Future<Result<Map<String, int>>> getFollowersCounts(List<String> merchantIds);

  /// Get the list of client user IDs that follow the given merchant.
  ///
  /// Requires a Firestore collection-group index on `followed_merchants`
  /// with field `merchant_id` (ascending).
  Future<Result<List<String>>> getFollowerIds(String merchantId);

  /// Get saved carnet sort indexes (merchantId → sort_index).
  /// Missing entries mean the merchant has never been manually reordered.
  Future<Result<Map<String, int>>> getFollowedSortIndexes(String userId);

  /// Persist carnet reorder. [sortIndexes] maps every visible merchantId
  /// to its new 0-based position. Uses a batched write.
  Future<Result<Unit>> updateSortOrder(String userId, Map<String, int> sortIndexes);
}
