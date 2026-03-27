import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/auth_failure.dart';
import '../domain/entities/user_profile_basics.dart';
import '../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/either.dart';
import '../../../../../core/domain/core/result.dart';
import '../../../../../core/infrastructure/logger_service.dart';
import '../../../../../types.dart';

/// Thrown inside [createUserDocument] transaction when phone is taken by another uid.
class DuplicatePhoneIndexException implements Exception {
  const DuplicatePhoneIndexException();
}

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

    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      return const Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(message: 'Le numéro de téléphone est requis'),
      );
    }

    const duplicateMsg = AuthUnexpectedFailure(
      message:
          'Vous avez déjà un compte avec ce numéro — nous ne créons pas deux comptes pour le même numéro. Connectez-vous.',
    );

    Map<String, dynamic> userPayload() => {
          'uid': uid,
          'email': email,
          'phone': phone,
          'roles': roles,
          'primary_role': roles['merchant'] == true ? 'merchant' : 'client',
          'city': city,
          'merchant_id': null,
          'onboarding': {
            'merchant': 'not_started',
          },
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_login_at': null,
          'force_merchant_next_login': roles['merchant'] == true,
        };

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(uid);
        final phoneIndexRef =
            _firestore.collection('phone_index').doc(normalizedPhone);

        final userSnap = await transaction.get(userRef);
        if (userSnap.exists) {
          throw const DuplicatePhoneIndexException();
        }

        final phoneSnap = await transaction.get(phoneIndexRef);
        if (phoneSnap.exists) {
          final existingUid = phoneSnap.data()?['uid'] as String?;
          if (existingUid != null && existingUid != uid) {
            throw const DuplicatePhoneIndexException();
          }
        } else {
          transaction.set(phoneIndexRef, {'uid': uid});
        }

        transaction.set(userRef, userPayload(), SetOptions(merge: false));
      });

      LoggerService.logInfo('User document created successfully',
          context: {'uid': uid, 'email': email, 'city': city});
      return const Right<AuthFailure, Unit>(unit);
    } on DuplicatePhoneIndexException {
      return const Left<AuthFailure, Unit>(duplicateMsg);
    } catch (e, st) {
      // phone_index requires matching Firestore rules; if rules are missing/outdated
      // the whole transaction fails and signup breaks. Fall back to users/ only.
      final isPermissionDenied =
          e is FirebaseException && e.code == 'permission-denied';
      if (isPermissionDenied) {
        LoggerService.logInfo(
          'createUserDocument: transaction denied (often phone_index rules); retrying users doc only',
          context: {'uid': uid},
        );
        try {
          final userRef = _firestore.collection('users').doc(uid);
          final existing = await userRef.get();
          if (existing.exists) {
            return const Left<AuthFailure, Unit>(duplicateMsg);
          }
          await userRef.set(userPayload(), SetOptions(merge: false));
          LoggerService.logInfo('User document created (fallback without phone_index)',
              context: {'uid': uid, 'email': email, 'city': city});
          return const Right<AuthFailure, Unit>(unit);
        } catch (e2, st2) {
          LoggerService.logError(
            'Error creating user document (fallback)',
            error: e2,
            stackTrace: st2,
            context: {'uid': uid},
          );
          if (e2 is FirebaseException && e2.code == 'permission-denied') {
            return const Left<AuthFailure, Unit>(
              AuthUnexpectedFailure(
                message:
                    'Permission refusée — impossible de créer le profil. Vérifiez la connexion ou réessayez.',
              ),
            );
          }
          return Left<AuthFailure, Unit>(
            AuthUnexpectedFailure(
              message:
                  'Erreur lors de la création du profil utilisateur: ${e2.toString()}',
              cause: e2,
              stackTrace: st2,
            ),
          );
        }
      }
      LoggerService.logError(
        'Error creating user document',
        error: e,
        stackTrace: st,
        context: {'uid': uid, 'email': email, 'phone': phone, 'city': city},
      );
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(
          message:
              'Erreur lors de la création du profil utilisateur: ${e.toString()}',
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

      // Signup intent / first account type — wins over flags toggled later.
      final primaryRaw = data['primary_role'];
      if (primaryRaw is String) {
        final p = primaryRaw.toLowerCase();
        if (p == 'merchant') {
          return const Right<AuthFailure, UserRole?>(UserRole.merchant);
        }
        if (p == 'client') {
          return const Right<AuthFailure, UserRole?>(UserRole.client);
        }
      }

      // Canonical: `roles` map on `/users/{uid}`. Legacy `role` string is migration-only.
      final roles = data['roles'] as Map<String, dynamic>?;
      if (roles != null) {
        if (roles['merchant'] == true) {
          return const Right<AuthFailure, UserRole?>(UserRole.merchant);
        }
        if (roles['client'] == true) {
          return const Right<AuthFailure, UserRole?>(UserRole.client);
        }
      }

      final legacyRole = data['role'] as String?;
      if (legacyRole != null) {
        final normalized = legacyRole.toLowerCase();
        if (normalized == 'merchant') {
          return const Right<AuthFailure, UserRole?>(UserRole.merchant);
        }
        if (normalized == 'client') {
          return const Right<AuthFailure, UserRole?>(UserRole.client);
        }
      }

      // Default to client when nothing else is present
      return const Right<AuthFailure, UserRole?>(UserRole.client);
    } catch (e, st) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied getting user role (non-fatal)',
          error: e,
          stackTrace: st,
          context: {'uid': uid},
        );
        // Returning null lets upper layers fall back to locally selected/cached role.
        return const Right<AuthFailure, UserRole?>(null);
      }
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
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied getting user city (non-fatal)',
          error: e,
          stackTrace: st,
          context: {'uid': uid},
        );
        return const Right<AuthFailure, String?>(null);
      }
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
  Future<Result<UserProfileBasics?>> getUserProfileBasics(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Right<AuthFailure, UserProfileBasics?>(null);
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, UserProfileBasics?>(null);
      }

      final email = (data['email'] as String?)?.trim() ?? '';
      final phone = (data['phone'] as String?)?.trim() ?? '';
      final city = (data['city'] as String?)?.trim() ?? '';

      if (email.isEmpty || phone.isEmpty || city.isEmpty) {
        return const Right<AuthFailure, UserProfileBasics?>(null);
      }

      return Right<AuthFailure, UserProfileBasics?>(
        UserProfileBasics(email: email, phone: phone, city: city),
      );
    } catch (e, st) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied getting user profile basics (non-fatal)',
          error: e,
          stackTrace: st,
          context: {'uid': uid},
        );
        return const Right<AuthFailure, UserProfileBasics?>(null);
      }
      LoggerService.logError(
        'Error getting user profile basics',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, UserProfileBasics?>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la récupération du profil utilisateur',
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
      LoggerService.logInfo('User city updated successfully',
          context: {'uid': uid, 'city': city});
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied updating user city (non-fatal)',
          error: e,
          stackTrace: st,
          context: {'uid': uid, 'city': city},
        );
        return const Right<AuthFailure, Unit>(unit);
      }
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
  Future<Result<List<String>>> getConnectedCities(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Right<AuthFailure, List<String>>([]);
      }
      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, List<String>>([]);
      }
      final citiesRaw = data['cities'];
      if (citiesRaw is List && citiesRaw.isNotEmpty) {
        final list = citiesRaw
            .map((e) => e?.toString().trim())
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList();
        return Right<AuthFailure, List<String>>(list);
      }
      final city = (data['city'] as String?)?.trim();
      if (city != null && city.isNotEmpty) {
        return Right<AuthFailure, List<String>>([city]);
      }
      return const Right<AuthFailure, List<String>>([]);
    } catch (e, st) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied getting connected cities (non-fatal)',
          error: e,
          stackTrace: st,
          context: {'uid': uid},
        );
        return const Right<AuthFailure, List<String>>([]);
      }
      LoggerService.logError(
        'Error getting connected cities',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, List<String>>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la récupération des villes',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> setConnectedCities({
    required String uid,
    required List<String> cities,
  }) async {
    try {
      final trimmed =
          cities.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final updateData = <String, dynamic>{
        'cities': trimmed,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (trimmed.isNotEmpty) {
        updateData['city'] = trimmed.first;
      }
      await _firestore.collection('users').doc(uid).update(updateData);
      LoggerService.logInfo(
        'Connected cities updated',
        context: {'uid': uid, 'count': trimmed.length},
      );
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied updating connected cities',
          error: e,
          stackTrace: st,
          context: {'uid': uid},
        );
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(
            message: 'Permission refusée / Permission denied',
          ),
        );
      }
      LoggerService.logError(
        'Error updating connected cities',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de l\'enregistrement des villes',
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
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied getting user roles (non-fatal)',
          error: e,
          stackTrace: st,
          context: {'uid': uid},
        );
        return const Right<AuthFailure, Map<String, bool>?>(null);
      }
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
      final primaryRole = (data['primary_role'] as String?)?.toLowerCase();
      final legacyRole = (data['role'] as String?)?.toLowerCase();
      final isMerchant = (roles != null && roles['merchant'] == true) ||
          primaryRole == 'merchant' ||
          legacyRole == 'merchant';
      if (!isMerchant) {
        // Not a merchant, return null
        return const Right<AuthFailure, bool?>(null);
      }

      // Canonical onboarding gate: users/{uid}.onboarding.merchant
      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      final onboardingValue =
          (onboarding?['merchant'] as String?)?.trim().toLowerCase();
      final onboardingCompleted = onboardingValue == 'completed';
      return Right<AuthFailure, bool?>(onboardingCompleted);
    } catch (e, st) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied checking onboarding status (non-fatal)',
          error: e,
          stackTrace: st,
          context: {'uid': uid},
        );
        return const Right<AuthFailure, bool?>(null);
      }
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
      final userRef = _firestore.collection('users').doc(uid);
      final doc = await userRef.get();
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

      // Legacy cleanup: some docs may contain literal dotted keys such as
      // `roles.client` / `roles.merchant` / `roles.provider`.
      final hasLegacyDottedRoleKeys = data.containsKey('roles.client') ||
          data.containsKey('roles.merchant') ||
          data.containsKey('roles.provider');
      if (hasLegacyDottedRoleKeys) {
        final cleaned = Map<String, dynamic>.from(data);
        final dottedClient = cleaned.remove('roles.client') == true;
        final dottedMerchant = cleaned.remove('roles.merchant') == true;
        final dottedProvider = cleaned.remove('roles.provider') == true;

        final existingRoles = cleaned['roles'] as Map<String, dynamic>?;
        final primaryRole = (cleaned['primary_role'] as String?)?.toLowerCase();
        final legacyRole = (cleaned['role'] as String?)?.toLowerCase();

        final isMerchant =
            (existingRoles != null && existingRoles['merchant'] == true) ||
                dottedMerchant ||
                primaryRole == 'merchant' ||
                legacyRole == 'merchant';
        final isClient = isMerchant
            ? false
            : (existingRoles != null && existingRoles['client'] == true) ||
                dottedClient ||
                primaryRole == 'client' ||
                legacyRole == 'client' ||
                true;
        final isProvider =
            (existingRoles != null && existingRoles['provider'] == true) ||
                dottedProvider ||
                isMerchant;

        cleaned['roles'] = <String, bool>{
          'client': isClient,
          'merchant': isMerchant,
          'provider': isProvider,
        };
        cleaned.remove('role');
        if (!cleaned.containsKey('merchant_id')) {
          cleaned['merchant_id'] = null;
        }
        final merchantId = (cleaned['merchant_id'] as String?)?.trim();
        cleaned['onboarding'] = {
          'merchant': (merchantId != null && merchantId.isNotEmpty)
              ? 'completed'
              : 'not_started',
        };
        if (cleaned['status'] == null) {
          cleaned['status'] = 'active';
        }
        if (!cleaned.containsKey('force_merchant_next_login')) {
          cleaned['force_merchant_next_login'] = false;
        }
        if (cleaned['last_login_at'] == false) {
          cleaned.remove('last_login_at');
        }
        if (cleaned['created_at'] == null) {
          cleaned['created_at'] = FieldValue.serverTimestamp();
        }
        cleaned['updated_at'] = FieldValue.serverTimestamp();

        await userRef.set(cleaned, SetOptions(merge: false));
        LoggerService.logInfo(
            'User document cleaned from legacy dotted role keys',
            context: {'uid': uid});
        return const Right<AuthFailure, Unit>(unit);
      }

      // Build update map with only missing fields
      final updates = <String, dynamic>{};

      // Drop legacy string if the canonical `roles` map exists (duplicate / old writes).
      if (data['roles'] != null && data.containsKey('role')) {
        updates['role'] = FieldValue.delete();
      }

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

      // Normalize onboarding marker for legacy users.
      final merchantId = (data['merchant_id'] as String?)?.trim();
      final currentOnboarding = data['onboarding'] as Map<String, dynamic>?;
      final currentMerchantStatus =
          (currentOnboarding?['merchant'] as String?)?.trim().toLowerCase();
      final targetMerchantStatus = (merchantId != null && merchantId.isNotEmpty)
          ? 'completed'
          : 'not_started';
      if (currentOnboarding == null ||
          currentMerchantStatus != targetMerchantStatus) {
        updates['onboarding'] = {'merchant': targetMerchantStatus};
      }

      // One-time: backfill primary_role from roles or legacy role string
      if (!data.containsKey('primary_role')) {
        final rolesMap = data['roles'] as Map<String, dynamic>?;
        if (rolesMap != null) {
          updates['primary_role'] =
              rolesMap['merchant'] == true ? 'merchant' : 'client';
        } else {
          final legacy = (data['role'] as String?)?.toLowerCase();
          if (legacy == 'merchant') {
            updates['primary_role'] = 'merchant';
          } else {
            updates['primary_role'] = 'client';
          }
        }
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

      // Ensure one-time first-login marker exists for legacy docs.
      if (!data.containsKey('force_merchant_next_login')) {
        updates['force_merchant_next_login'] = false;
      }

      // Legacy sentinel: remove bool false so field is absent until [updateLastLoginAt].
      if (data['last_login_at'] == false) {
        updates['last_login_at'] = FieldValue.delete();
      }

      // Only update if there are changes
      if (updates.isNotEmpty) {
        await userRef.update(updates);
        LoggerService.logInfo('User document patched successfully',
            context: {'uid': uid, 'fieldsUpdated': updates.keys.toList()});
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
          message:
              'Erreur lors de la mise à jour du profil utilisateur: ${e.toString()}',
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
      LoggerService.logInfo('Last login timestamp updated successfully',
          context: {'uid': uid});
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
      LoggerService.logInfo(
          'Continuing login despite last_login_at update failure',
          context: {'uid': uid});
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
      final hasEmail =
          data['email'] != null && (data['email'] as String).isNotEmpty;
      final hasPhone =
          data['phone'] != null && (data['phone'] as String).isNotEmpty;
      final hasCity =
          data['city'] != null && (data['city'] as String).isNotEmpty;

      // Roles: canonical `roles` map, or legacy `role` string until patched on login.
      final hasRoles = data['roles'] != null ||
          (data['role'] != null &&
              (data['role'] as String).toString().trim().isNotEmpty);
      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      final onboardingMerchant =
          (onboarding?['merchant'] as String?)?.trim().toLowerCase();
      final hasOnboarding = onboardingMerchant == 'not_started' ||
          onboardingMerchant == 'completed';
      final hasStatus = data['status'] is String &&
          ((data['status'] as String).trim().isNotEmpty);
      final hasMerchantIdField = data.containsKey('merchant_id');

      final isComplete = hasUid &&
          hasEmail &&
          hasPhone &&
          hasCity &&
          hasRoles &&
          hasOnboarding &&
          hasStatus &&
          hasMerchantIdField;
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

  @override
  Future<Result<bool>> consumeForceMerchantNextLogin(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final shouldForce = await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) return false;
        final data = snap.data();
        final enabled = data?['force_merchant_next_login'] == true;
        if (enabled) {
          tx.update(userRef, {
            'force_merchant_next_login': false,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        return enabled;
      });
      return Right<AuthFailure, bool>(shouldForce);
    } catch (e, st) {
      LoggerService.logError(
        'Error consuming force_merchant_next_login',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return const Right<AuthFailure, bool>(false);
    }
  }
}
