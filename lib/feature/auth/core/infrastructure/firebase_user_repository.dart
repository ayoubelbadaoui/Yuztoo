import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/auth_failure.dart';
import '../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/either.dart';
import '../../../../../core/domain/core/result.dart';
import '../../../../../core/infrastructure/logger_service.dart';
import '../../../../../types.dart';

/// Firebase implementation of UserRepository
class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Result<Unit>> createUserDocument({
    required String uid,
    required String email,
    required String phone,
    required Map<String, bool> roles,
    required String city,
  }) async {
    if (city.isEmpty) {
      return const Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(message: 'La ville est requise'),
      );
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'phone': phone,
        'roles': roles,
        'city': city,
        'merchant_id': null, // Nullable, set when merchant completes onboarding
        'status': 'active', // Default status
        'onboarding': {
          'merchant': false, // Default to incomplete
        },
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_login_at': false, // False on creation, updated on sign-in
      }, SetOptions(merge: false));
      LoggerService.logInfo('User document created successfully', context: {'uid': uid, 'email': email, 'city': city});
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      LoggerService.logError(
        'Error creating user document',
        error: e,
        stackTrace: st,
        context: {'uid': uid, 'email': email, 'phone': phone, 'city': city},
      );
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la création du profil utilisateur: ${e.toString()}',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<UserRole?>> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Right<AuthFailure, UserRole?>(null);
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, UserRole?>(null);
      }

      final roles = data['roles'] as Map<String, dynamic>?;
      if (roles != null) {
        if (roles['merchant'] == true) {
          return const Right<AuthFailure, UserRole?>(UserRole.merchant);
        }
        if (roles['client'] == true) {
          return const Right<AuthFailure, UserRole?>(UserRole.client);
        }
      }

      // Fallback for legacy schema using a single "role" string
      final legacyRole = data['role'] as String?;
      if (legacyRole != null) {
        final normalized = legacyRole.toLowerCase();
        if (normalized == 'merchant') {
          return const Right<AuthFailure, UserRole?>(UserRole.merchant);
        }
        return const Right<AuthFailure, UserRole?>(UserRole.client);
      }

      // Default to client when nothing else is present
      return const Right<AuthFailure, UserRole?>(UserRole.client);
    } catch (e, st) {
      LoggerService.logError(
        'Error getting user role',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, UserRole?>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la récupération du rôle utilisateur',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<String?>> getUserCity(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Right<AuthFailure, String?>(null);
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, String?>(null);
      }

      final city = data['city'] as String?;
      // Return null if city is null or empty
      if (city == null || city.isEmpty) {
        return const Right<AuthFailure, String?>(null);
      }

      return Right<AuthFailure, String?>(city);
    } catch (e, st) {
      LoggerService.logError(
        'Error getting user city',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, String?>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la récupération de la ville',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> updateUserCity({
    required String uid,
    required String city,
  }) async {
    if (city.isEmpty) {
      LoggerService.logFailure(
        'ValidationFailure',
        'City is required for user city update',
        context: {'uid': uid},
      );
      return const Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(message: 'La ville est requise'),
      );
    }

    try {
      await _firestore.collection('users').doc(uid).update({
        'city': city,
        'updated_at': FieldValue.serverTimestamp(),
      });
      LoggerService.logInfo('User city updated successfully', context: {'uid': uid, 'city': city});
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      LoggerService.logError(
        'Error updating user city',
        error: e,
        stackTrace: st,
        context: {'uid': uid, 'city': city},
      );
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la mise à jour de la ville: ${e.toString()}',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, bool>?>> getUserRoles(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Right<AuthFailure, Map<String, bool>?>(null);
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, Map<String, bool>?>(null);
      }

      final roles = data['roles'] as Map<String, dynamic>?;
      if (roles != null) {
        // Convert to Map<String, bool>
        final rolesMap = <String, bool>{
          'client': roles['client'] == true,
          'merchant': roles['merchant'] == true,
          'provider': roles['provider'] == true,
        };
        return Right<AuthFailure, Map<String, bool>?>(rolesMap);
      }

      // Fallback for legacy schema using a single "role" string
      final legacyRole = data['role'] as String?;
      if (legacyRole != null) {
        final normalized = legacyRole.toLowerCase();
        final rolesMap = <String, bool>{
          'client': normalized != 'merchant', // default client if not merchant
          'merchant': normalized == 'merchant',
          'provider': false,
        };
        return Right<AuthFailure, Map<String, bool>?>(rolesMap);
      }

      // Nothing found
      return const Right<AuthFailure, Map<String, bool>?>(null);
    } catch (e, st) {
      LoggerService.logError(
        'Error getting user roles',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, Map<String, bool>?>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la récupération des rôles utilisateur',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<bool?>> isMerchantOnboardingCompleted(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Right<AuthFailure, bool?>(null);
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, bool?>(null);
      }

      final roles = data['roles'] as Map<String, dynamic>?;
      if (roles == null || roles['merchant'] != true) {
        // Not a merchant, return null
        return const Right<AuthFailure, bool?>(null);
      }

      // Check onboarding status from nested onboarding.merchant field
      // Falls back to false if not set (defaults to incomplete)
      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      final onboardingCompleted = onboarding?['merchant'] as bool? ?? false;
      return Right<AuthFailure, bool?>(onboardingCompleted);
    } catch (e, st) {
      LoggerService.logError(
        'Error checking onboarding status',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, bool?>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la vérification de l\'onboarding',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> patchUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'User document does not exist'),
        );
      }

      final data = doc.data();
      if (data == null) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'User document data is null'),
        );
      }

      // Build update map with only missing fields
      final updates = <String, dynamic>{};

      // Convert legacy single role string to roles map if needed
      if (data['roles'] == null && data['role'] != null) {
        final legacyRole = (data['role'] as String).toLowerCase();
        updates['roles'] = {
          'client': legacyRole != 'merchant',
          'merchant': legacyRole == 'merchant',
          'provider': false,
        };
        // Remove legacy role field
        updates['role'] = FieldValue.delete();
      } else if (data['roles'] == null) {
        // No roles at all - default to client
        updates['roles'] = {
          'client': true,
          'merchant': false,
          'provider': false,
        };
      }

      // Initialize onboarding if missing
      if (data['onboarding'] == null) {
        updates['onboarding'] = {
          'merchant': false,
        };
      }

      // Set default status if missing
      if (data['status'] == null) {
        updates['status'] = 'active';
      }

      // Set merchant_id to null if missing (explicit null for nullable field)
      if (!data.containsKey('merchant_id')) {
        updates['merchant_id'] = null;
      }

      // Set created_at if missing (shouldn't happen, but safety check)
      if (data['created_at'] == null) {
        updates['created_at'] = FieldValue.serverTimestamp();
      }

      // Set updated_at (always update on patch)
      updates['updated_at'] = FieldValue.serverTimestamp();

      // Only update if there are changes
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
        LoggerService.logInfo('User document patched successfully', context: {'uid': uid, 'fieldsUpdated': updates.keys.toList()});
      }

      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      LoggerService.logError(
        'Error patching user document',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la mise à jour du profil utilisateur: ${e.toString()}',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> updateLastLoginAt(String uid) async {
    try {
      // Use update() with server timestamp for consistency and concurrent login safety
      await _firestore.collection('users').doc(uid).update({
        'last_login_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      LoggerService.logInfo('Last login timestamp updated successfully', context: {'uid': uid});
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      LoggerService.logError(
        'Error updating last login timestamp',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      // Don't fail login if this fails - log but continue
      // Return success to not block user login
      LoggerService.logInfo('Continuing login despite last_login_at update failure', context: {'uid': uid});
      return const Right<AuthFailure, Unit>(unit);
    }
  }

  @override
  Future<Result<bool>> checkUserProfileComplete(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Right<AuthFailure, bool>(false);
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, bool>(false);
      }

      // Check required fields
      final hasUid = data['uid'] != null && (data['uid'] as String).isNotEmpty;
      final hasEmail = data['email'] != null && (data['email'] as String).isNotEmpty;
      final hasPhone = data['phone'] != null && (data['phone'] as String).isNotEmpty;
      final hasCity = data['city'] != null && (data['city'] as String).isNotEmpty;
      
      // Check roles - either new format (roles map) or legacy (role string)
      final hasRoles = data['roles'] != null || data['role'] != null;

      final isComplete = hasUid && hasEmail && hasPhone && hasCity && hasRoles;
      return Right<AuthFailure, bool>(isComplete);
    } catch (e, st) {
      LoggerService.logError(
        'Error checking profile completeness',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      // On error, assume incomplete (safer default)
      return const Right<AuthFailure, bool>(false);
    }
  }
}

