import '../../../../core/domain/core/result.dart';
import '../entities/merchant_storefront_link.dart';
import '../entities/client_gratification_config.dart';
import '../entities/loyalty_program_config.dart';
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

  /// Get merchant by document ID (for client store profile).
  /// 
  /// [merchantId] - Firestore document ID of the merchant
  /// 
  /// Returns Result<Merchant?> - Merchant if found, null if not found
  Future<Result<Merchant?>> getMerchantById(String merchantId);

  /// List merchants for client home / discovery (e.g. "Mon carnet").
  ///
  /// [limit] - Max number of merchants to return (default 20)
  /// [cityFilter] - Single-city convenience filter (case-insensitive). Kept
  ///   for backward compatibility with callers that only care about one city.
  /// [cityFilters] - Multi-city OR-filter (case-insensitive). When non-empty,
  ///   takes precedence over [cityFilter] and returns merchants whose city
  ///   matches ANY entry. Used by Découvrir so a client with multiple
  ///   "connected cities" sees merchants from all of them.
  /// [cityFetchCap] - When any city filter is active, scans up to this many
  ///   recently-updated documents so commerces that just set their city still
  ///   appear for matching clients.
  ///
  /// Returns Result<List<Merchant>> - List of merchants, ordered by updated_at descending
  Future<Result<List<Merchant>>> listMerchants({
    int limit = 20,
    String? cityFilter,
    List<String>? cityFilters,
    int cityFetchCap = 500,
  });

  /// List merchants by their document IDs (e.g. for followed merchants).
  /// 
  /// [ids] - List of merchant document IDs
  /// 
  /// Returns Result<List<Merchant>> - Merchants that exist, in the order of [ids] where possible
  Future<Result<List<Merchant>>> getMerchantsByIds(List<String> ids);

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

  /// Update merchant storefront fields.
  ///
  /// Updates display_name, description, categories, logo_url, phone, address,
  /// website_url, banner_url, and hours in Firestore.
  ///
  /// [merchantId] - ID of the merchant to update
  /// [displayName] - Display name for storefront (optional)
  /// [description] - Business description (optional)
  /// [categories] - List of categories (optional)
  /// [logoUrl] - Logo URL from Firebase Storage (optional)
  /// [phone] - Business phone (optional)
  /// [address] - Business address (optional)
  /// [websiteUrl] - Website URL (optional)
  /// [bannerUrl] - Banner image URL from Firebase Storage (optional)
  /// [newsImageUrls] - Actualite slider image URLs (optional)
  /// [status] - Merchant visibility status ('active' or 'inactive')
  /// [hours] - Business hours map (optional)
  /// [rappelsAutoClientValidation] - Rappels: auto-validate new clients (optional)
  /// [rappelsAutoPassageValidation] - Rappels: auto-validate passage (optional)
  /// [passageCooldownEnabled] - 1 h minimum between passages per client (default on)
  /// [loyaltyProgram] - Full loyalty questionnaire payload (optional)
  /// [clearCityField] - When true and [city] is null, removes `city` on the merchant (and syncs user doc).
  ///
  /// Returns Result<Merchant> on success, Result with failure on error
  Future<Result<Merchant>> updateMerchant({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoUrl,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    String? welcomeGiftDescription,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
    bool? passageCooldownEnabled,
    LoyaltyProgramConfig? loyaltyProgram,
    bool? messagingEnabled,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabledStandalone,
    String? merchantType,
    String? categoryId,
    String? subcategoryTitle,
    bool clearCityField = false,
    List<MerchantStorefrontLink>? storefrontLinks,
  });

  /// Persist the merchant's client gratification configuration.
  Future<Result<void>> updateGratificationConfig({
    required String merchantId,
    required ClientGratificationConfig config,
  });
}

