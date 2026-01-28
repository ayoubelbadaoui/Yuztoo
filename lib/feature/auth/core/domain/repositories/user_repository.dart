import '../../../../../core/domain/core/result.dart';
import '../../../../../types.dart';

/// Repository interface for user profile operations in Firestore
/// 
/// This interface is in the domain layer and contains no Firebase types.
/// Implementations should be in the infrastructure layer.
abstract class UserRepository {
  /// Create a user document in Firestore
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
    required String city,
  });

  /// Get user role from Firestore
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Returns Result<UserRole?> - UserRole if found, null if document doesn't exist or roles invalid
  Future<Result<UserRole?>> getUserRole(String uid);

  /// Get user's city from Firestore
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Returns Result<String?> - City if found, null if document doesn't exist or city not set
  Future<Result<String?>> getUserCity(String uid);

  /// Update user's city in Firestore
  /// 
  /// [uid] - User's unique identifier
  /// [city] - User's city (required, non-empty)
  /// 
  /// Returns Result<Unit> on success, Result with failure on error
  Future<Result<Unit>> updateUserCity({required String uid, required String city});

  /// Get user's roles map from Firestore
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Returns Result<Map<String, bool>?> - Roles map if found, null if document doesn't exist
  Future<Result<Map<String, bool>?>> getUserRoles(String uid);

  /// Check if merchant onboarding is completed
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Returns Result<bool?> - true if onboarding completed, false if not, null if document doesn't exist
  Future<Result<bool?>> isMerchantOnboardingCompleted(String uid);
}

