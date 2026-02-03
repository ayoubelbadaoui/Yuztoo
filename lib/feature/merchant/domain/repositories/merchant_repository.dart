import '../../../../core/domain/core/result.dart';
import '../entities/merchant.dart';

/// Repository interface for merchant operations in Firestore.
/// 
/// This interface is in the domain layer and contains no Firebase types.
/// Implementations should be in the infrastructure layer.
abstract class MerchantRepository {
  /// Check if a merchant already exists for the given owner UID.
  /// 
  /// [ownerUid] - User ID of the merchant owner
  /// 
  /// Returns Result<bool> - true if merchant exists, false otherwise
  Future<Result<bool>> merchantExists(String ownerUid);

  /// Create a merchant document and link it to the user atomically.
  /// 
  /// This operation uses a Firestore batch write to ensure atomicity:
  /// - Creates merchant document in /merchants/{merchantId}
  /// - Updates user document in /users/{uid} with merchant_id field
  /// 
  /// [merchant] - Merchant entity to create
  /// [userId] - User ID to link the merchant to
  /// 
  /// Returns Result<Merchant> on success, Result with failure on error
  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  });

  /// Get merchant by owner UID.
  /// 
  /// [ownerUid] - User ID of the merchant owner
  /// 
  /// Returns Result<Merchant?> - Merchant if found, null if not found
  Future<Result<Merchant?>> getMerchantByOwnerUid(String ownerUid);

  /// Link an existing merchant to a user (recovery for edge case: merchant exists but user not linked).
  /// 
  /// This method handles the edge case where a merchant document exists but the user
  /// document doesn't have the merchant_id field set. This can happen in rare scenarios
  /// like partial batch failures or data inconsistencies.
  /// 
  /// [merchantId] - ID of the existing merchant
  /// [userId] - User ID to link the merchant to
  /// 
  /// Returns Result<Unit> on success, Result with failure on error
  Future<Result<Unit>> linkExistingMerchantToUser({
    required String merchantId,
    required String userId,
  });

  /// Get merchant by merchant ID.
  /// 
  /// [merchantId] - Unique identifier for the merchant document
  /// 
  /// Returns Result<Merchant?> - Merchant if found, null if not found
  Future<Result<Merchant?>> getMerchantById(String merchantId);

  /// Get all active merchants, optionally filtered by city.
  /// 
  /// [city] - Optional city filter. If provided, returns only merchants in that city.
  ///          If null, returns all active merchants.
  /// 
  /// Returns Result<List<Merchant>> - List of active merchants, empty list if none found
  Future<Result<List<Merchant>>> getMerchants({String? city});
}

