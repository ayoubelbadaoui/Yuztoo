import '../../../../../core/domain/core/result.dart';
import '../../../../../types.dart';
import '../entities/user_profile_basics.dart';

/// Repository interface for user profile operations in Firestore
///
/// This interface is in the domain layer and contains no Firebase types.
/// Implementations should be in the infrastructure layer.
///
/// User Schema (/users/{uid}):
/// - uid: String (required)
/// - email: String (required)
/// - phone: String (required)
/// - city: String (required)
/// - roles: Map<String, bool> (required) - {"client": bool, "merchant": bool, "provider": bool}
///   Signup: client XOR merchant (`client` and `merchant` are not both true); merchants also set `provider`.
/// - primary_role: String — `"merchant"` | `"client"` (first signup intent; login follows this).
/// - merchant_id: String? (nullable, set when merchant completes onboarding)
/// - status: String (default: "active")
/// - created_at: Timestamp (server timestamp)
/// - updated_at: Timestamp (server timestamp)
/// - last_login_at: Timestamp? (null until first sign-in)
abstract class UserRepository {
  /// Create a user document in Firestore with full schema
  ///
  /// Creates a new user document with all required and optional fields.
  /// All new users will have the complete schema including merchant_id (null),
  /// status ("active"), onboarding.merchant ("not_started"), and last_login_at (null).
  ///
  /// [uid] - User's unique identifier
  /// [email] - User's email address
  /// [phone] - User's phone number (formatted with country code)
  /// [roles] - Map of user roles: {"client": bool, "merchant": bool, "provider": bool}
  /// [city] - User's city (required, non-empty)
  ///
  /// Returns Result<Unit> on success, Result with failure on error
  Future<Result<Unit>> createUserDocument({
    required String uid,
    required String email,
    required String phone,
    required Map<String, bool> roles,
    String city = '',
  });

  /// Get user role from Firestore
  ///
  /// [uid] - User's unique identifier
  ///
  /// Returns Result<UserRole?> - UserRole if found, null if document doesn't exist or roles invalid
  Future<Result<UserRole?>> getUserRole(String uid);

  /// Get user city from Firestore
  ///
  /// [uid] - User's unique identifier
  ///
  /// Returns Result<String?> - City if found, null if document doesn't exist or city is empty
  Future<Result<String?>> getUserCity(String uid);

  /// Get user email/phone/city from Firestore.
  ///
  /// Used to avoid asking the user to re-enter signup information when
  /// completing merchant onboarding.
  ///
  /// Returns Result<UserProfileBasics?> - null if doc missing or fields unavailable.
  Future<Result<UserProfileBasics?>> getUserProfileBasics(String uid);

  /// Get all user roles from Firestore
  ///
  /// [uid] - User's unique identifier
  ///
  /// Returns Result<Map<String, bool>?> - Roles map if found, null if document doesn't exist
  Future<Result<Map<String, bool>?>> getUserRoles(String uid);

  /// Check if merchant onboarding is completed (via `onboarding.merchant`)
  ///
  /// [uid] - User's unique identifier
  ///
  /// Returns Result<bool?> - true if completed, false if not, null if not a merchant or document doesn't exist
  Future<Result<bool?>> isMerchantOnboardingCompleted(String uid);

  /// Check if client profile onboarding is completed (`onboarding.client`).
  ///
  /// Returns `null` if the user is not a client. For legacy docs without
  /// `onboarding.client`, returns `true` so existing users are not gated.
  Future<Result<bool?>> isClientOnboardingCompleted(String uid);

  /// Saves display name, optional photo URL, and marks `onboarding.client` completed.
  Future<Result<Unit>> completeClientProfile({
    required String uid,
    required String displayName,
    String? city,
    String? photoUrl,
  });

  /// Marks merchant acquisition onboarding complete (`onboarding.merchant` = completed).
  ///
  /// Used when the user finishes the pre-signup onboarding wizard (post-signup path).
  Future<Result<Unit>> markMerchantOnboardingCompleted(String uid);

  /// Update user city in Firestore
  ///
  /// [uid] - User's unique identifier
  /// [city] - New city value (required, non-empty)
  ///
  /// Returns Result<Unit> on success, Result with failure on error
  Future<Result<Unit>> updateUserCity({
    required String uid,
    required String city,
  });

  /// Get connected cities for the user (from Firestore).
  /// Returns [city] if no cities array, else the cities array.
  Future<Result<List<String>>> getConnectedCities(String uid);

  /// Set connected cities in Firestore (replaces the list and updates city to first).
  Future<Result<Unit>> setConnectedCities({
    required String uid,
    required List<String> cities,
  });

  /// Patch missing fields in user document for legacy users
  ///
  /// Updates only missing required fields without overwriting existing data.
  /// Handles migration from legacy schema (single role string) to new schema (roles map).
  ///
  /// [uid] - User's unique identifier
  ///
  /// Returns Result<Unit> on success, Result with failure on error
  Future<Result<Unit>> patchUserDocument(String uid);

  /// Update last_login_at timestamp on successful sign-in
  ///
  /// Uses server timestamp to ensure consistency and handle concurrent logins.
  ///
  /// [uid] - User's unique identifier
  ///
  /// Returns Result<Unit> on success, Result with failure on error
  Future<Result<Unit>> updateLastLoginAt(String uid);

  /// Consumes one-time merchant-first-login marker from Firestore.
  ///
  /// Returns true once (when flag was set), then resets it to false atomically.
  Future<Result<bool>> consumeForceMerchantNextLogin(String uid);

  /// Check if user profile is complete with all required fields
  ///
  /// Required fields: uid, email, phone, city, roles
  /// Optional but should exist: merchant_id, status, created_at, updated_at
  ///
  /// [uid] - User's unique identifier
  ///
  /// Returns Result<bool> - true if complete, false if incomplete
  Future<Result<bool>> checkUserProfileComplete(String uid);

  /// Whether [phone] (E.164, trimmed) already has a row in [phone_index] (account exists).
  ///
  /// Used before SMS OTP so the user sees an error on signup instead of the auth screen.
  Future<Result<bool>> isPhoneNumberRegistered(String phone);

  /// Whether [email] (lowercased, trimmed) already has a row in [email_index] (account exists).
  ///
  /// Used before signup to show an error early instead of letting Firebase Auth reject later.
  Future<Result<bool>> isEmailRegistered(String email);
}
