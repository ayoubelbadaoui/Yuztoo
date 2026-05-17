part of 'firebase_user_repository.dart';

mixin _FirebaseUserRepositoryReads on _FirebaseUserRepositoryBase {
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
      if (city == null || city.isEmpty) {
        return const Right<AuthFailure, String?>(null);
      }
      if (CityInput.isPlaceholder(city)) {
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
      final rawCity = (data['city'] as String?)?.trim() ?? '';
      final city = CityInput.isPlaceholder(rawCity) ? '' : rawCity;
      final firstName = (data['first_name'] as String?)?.trim();
      final lastName = (data['last_name'] as String?)?.trim();
      final dobRaw = data['date_of_birth'] as String?;
      DateTime? dateOfBirth;
      if (dobRaw != null && dobRaw.isNotEmpty) {
        dateOfBirth = DateTime.tryParse(dobRaw);
      }

      // Always return basics when the document exists so UI can show fields
      // even if some are temporarily empty.
      return Right<AuthFailure, UserProfileBasics?>(
        UserProfileBasics(
          email: email,
          phone: phone,
          city: city,
          firstName: firstName?.isNotEmpty == true ? firstName : null,
          lastName: lastName?.isNotEmpty == true ? lastName : null,
          dateOfBirth: dateOfBirth,
        ),
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

  Future<Result<Unit>> setConnectedCities({
    required String uid,
    required List<String> cities,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snap = await userRef.get();
      if (!snap.exists || snap.data() == null) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(
            message:
                'Profil introuvable. Reconnectez-vous. / Profile not found. Please sign in again.',
          ),
        );
      }

      final trimmed =
          cities.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final existing = Map<String, dynamic>.from(snap.data()!);
      final updateData = <String, dynamic>{
        'cities': trimmed,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (trimmed.isNotEmpty) {
        final primary = CityInput.forFirestore(trimmed.first);
        if (primary != null) {
          updateData['city'] = primary;
        }
      }
      mergeUserPatchForFirestoreRules(existing, updateData);

      await userRef.set(updateData, SetOptions(merge: true));
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
            message: 'Permission refusée',
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

  Future<Result<bool?>> isClientOnboardingCompleted(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      // No doc yet (e.g. auth emitted before Firestore write) → not completed.
      if (!doc.exists) {
        return const Right<AuthFailure, bool?>(false);
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, bool?>(false);
      }

      final roles = data['roles'] as Map<String, dynamic>?;
      final primaryRole = (data['primary_role'] as String?)?.toLowerCase();
      final legacyRole = (data['role'] as String?)?.toLowerCase();
      final isClient = (roles != null && roles['client'] == true) ||
          primaryRole == 'client' ||
          legacyRole == 'client';
      if (!isClient) {
        return const Right<AuthFailure, bool?>(null);
      }

      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      // Legacy: no `onboarding` object at all → old accounts; don't force onboarding.
      if (onboarding == null) {
        return const Right<AuthFailure, bool?>(true);
      }
      final clientRaw = (onboarding['client'] as String?)?.trim().toLowerCase();
      // `onboarding` exists but `client` missing/empty → new signup partial write or pending.
      if (clientRaw == null || clientRaw.isEmpty) {
        return const Right<AuthFailure, bool?>(false);
      }
      return Right<AuthFailure, bool?>(clientRaw == 'completed');
    } catch (e, st) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        LoggerService.logError(
          'Permission denied checking client onboarding (non-fatal)',
          error: e,
          stackTrace: st,
          context: {'uid': uid},
        );
        // Fail closed: prefer showing onboarding until reads succeed.
        return const Right<AuthFailure, bool?>(false);
      }
      LoggerService.logError(
        'Error checking client onboarding status',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, bool?>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la vérification du profil client',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Result<ClientProfileReadiness>> getClientProfileReadiness(
      String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return Right<AuthFailure, ClientProfileReadiness>(
          ClientProfileReadiness(
            hasClientRole: false,
            onboardingCompleted: false,
            missingForClientHome: computeMissingClientProfileFields(
              firstName: null,
              lastName: null,
              dateOfBirth: null,
              city: null,
              photoUrl: null,
            ),
          ),
        );
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, ClientProfileReadiness>(
          ClientProfileReadiness(
            hasClientRole: false,
            onboardingCompleted: false,
            missingForClientHome: [
              ClientProfileMissingField.firstName,
              ClientProfileMissingField.lastName,
              ClientProfileMissingField.dateOfBirth,
              ClientProfileMissingField.city,
              ClientProfileMissingField.photo,
            ],
          ),
        );
      }

      final roles = data['roles'] as Map<String, dynamic>?;
      final hasClientRole = roles?['client'] == true;

      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      final clientRaw =
          (onboarding?['client'] as String?)?.trim().toLowerCase();
      final onboardingCompleted = onboarding == null
          ? hasClientRole
          : (clientRaw == 'completed');

      final firstName = (data['first_name'] as String?)?.trim();
      final lastName = (data['last_name'] as String?)?.trim();
      final dobRaw = data['date_of_birth'] as String?;
      DateTime? dateOfBirth;
      if (dobRaw != null && dobRaw.isNotEmpty) {
        dateOfBirth = DateTime.tryParse(dobRaw);
      }
      final rawCity = (data['city'] as String?)?.trim() ?? '';
      final city = CityInput.isPlaceholder(rawCity) ? '' : rawCity;
      final photoUrl = (data['photoUrl'] as String?)?.trim();
      final displayName = (data['displayName'] as String?)?.trim();

      final missing = computeMissingClientProfileFields(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        city: city.isEmpty ? null : city,
        photoUrl: photoUrl,
      );

      return Right<AuthFailure, ClientProfileReadiness>(
        ClientProfileReadiness(
          hasClientRole: hasClientRole,
          onboardingCompleted: onboardingCompleted,
          missingForClientHome: missing,
          firstName: firstName?.isNotEmpty == true ? firstName : null,
          lastName: lastName?.isNotEmpty == true ? lastName : null,
          dateOfBirth: dateOfBirth,
          city: city.isEmpty ? null : city,
          photoUrl: photoUrl?.isNotEmpty == true ? photoUrl : null,
          displayName: displayName?.isNotEmpty == true ? displayName : null,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Error reading client profile readiness',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, ClientProfileReadiness>(
        AuthUnexpectedFailure(
          message: 'Impossible de vérifier le profil client',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Result<Unit>> completeClientProfile({
    required String uid,
    required String displayName,
    String? city,
    String? photoUrl,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return const Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(message: 'Le nom est requis'),
      );
    }

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snap = await userRef.get();

      // Guard: if the Firestore doc was never created during signup (e.g. the
      // phone_index transaction was denied and the fallback also failed), build
      // a minimal valid document now so onboarding can still complete.
      if (!snap.exists) {
        // ignore: avoid_print
        print('[completeClientProfile] user doc missing for uid=$uid — creating minimal doc');
        final authUser = FirebaseAuth.instance.currentUser;
        final minimalDoc = <String, dynamic>{
          'uid': uid,
          'email': authUser?.email ?? '',
          'phone': authUser?.phoneNumber ?? '',
          'roles': <String, bool>{'client': true, 'merchant': false, 'provider': false},
          'primary_role': 'client',
          'merchant_id': null,
          'onboarding': <String, String>{'merchant': 'completed', 'client': 'not_started'},
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_login_at': null,
          'force_merchant_next_login': false,
        };
        await userRef.set(minimalDoc, SetOptions(merge: false));
        LoggerService.logInfo('completeClientProfile: created missing user doc', context: {'uid': uid});
      }

      final freshSnap = snap.exists ? snap : await userRef.get();
      final data = freshSnap.data();
      // Build the merged onboarding map by reading the latest value and only
      // overwriting `client`. Two bugs the previous code hit:
      //   1. `putIfAbsent('merchant', () => 'completed')` would silently mark
      //      merchant onboarding as DONE for a brand-new dual-profile upgrade
      //      where the merchant key happened to be missing — the user got
      //      skipped past merchant onboarding even though they never went
      //      through it. The "default if missing" must be 'not_started',
      //      not 'completed'.
      //   2. Writing the merged map back as a nested literal worked here only
      //      because we read it first, but any other writer that does
      //      `update({'onboarding': {...}})` would have replaced the whole
      //      nested map silently.
      final mergedOnboarding = Map<String, dynamic>.from(
        (data?['onboarding'] as Map<String, dynamic>?) ?? {},
      );
      mergedOnboarding['client'] = 'completed';
      mergedOnboarding.putIfAbsent('merchant', () => 'not_started');

      final update = <String, dynamic>{
        'displayName': trimmed,
        'onboarding': mergedOnboarding,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (photoUrl != null && photoUrl.trim().isNotEmpty) {
        update['photoUrl'] = photoUrl.trim();
      }
      final trimmedCity = CityInput.forFirestore(city ?? '');
      if (trimmedCity != null) {
        update['city'] = trimmedCity;
      }
      if (firstName != null && firstName.trim().isNotEmpty) {
        update['first_name'] = firstName.trim();
      }
      if (lastName != null && lastName.trim().isNotEmpty) {
        update['last_name'] = lastName.trim();
      }
      if (dateOfBirth != null) {
        update['date_of_birth'] =
            '${dateOfBirth.year.toString().padLeft(4, '0')}-'
            '${dateOfBirth.month.toString().padLeft(2, '0')}-'
            '${dateOfBirth.day.toString().padLeft(2, '0')}';
      }

      if (data != null) mergeUserPatchForFirestoreRules(data, update);
      await userRef.update(update);
      LoggerService.logInfo(
        'Client profile onboarding completed',
        context: {'uid': uid},
      );
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      // ignore: avoid_print
      print('[completeClientProfile] EXCEPTION for uid=$uid: $e');
      LoggerService.logError(
        'Error completing client profile',
        error: e,
        stackTrace: st,
        context: {'uid': uid, 'error': e.toString()},
      );
      // Return more specific error message for debugging
      String message = 'Erreur lors de l\'enregistrement du profil';
      if (e.toString().contains('permission-denied')) {
        message = 'Permission refusée. Vérifiez les règles Firestore.';
      }
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(
          message: message,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Result<Unit>> updateClientBasicInfo({
    required String uid,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? ownerEmail,
    String? photoUrl,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snap = await userRef.get();
      if (!snap.exists || snap.data() == null) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(
            message: 'Profil introuvable. Reconnectez-vous.',
          ),
        );
      }

      final existing = Map<String, dynamic>.from(snap.data()!);
      final update = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      final fn = firstName?.trim() ?? '';
      final ln = lastName?.trim() ?? '';

      if (fn.isNotEmpty) {
        update['first_name'] = fn;
        // Build displayName: use incoming lastName if provided, else fall back
        // to whatever is already in Firestore so we never drop the last name
        // just because only firstName was passed.
        final existingLn = (existing['last_name'] as String? ?? '').trim();
        final effectiveLn = ln.isNotEmpty ? ln : existingLn;
        update['displayName'] = effectiveLn.isNotEmpty ? '$fn $effectiveLn' : fn;
      }

      if (ln.isNotEmpty) {
        update['last_name'] = ln;
      }

      if (dateOfBirth != null) {
        update['date_of_birth'] =
            '${dateOfBirth.year.toString().padLeft(4, '0')}-'
            '${dateOfBirth.month.toString().padLeft(2, '0')}-'
            '${dateOfBirth.day.toString().padLeft(2, '0')}';
      }

      final oe = ownerEmail?.trim() ?? '';
      if (oe.isNotEmpty) {
        update['owner_email'] = oe.toLowerCase();
      }

      // Mirror the avatar URL from Firebase Auth into Firestore so anything
      // that reads users/{uid}.photoUrl (e.g. the merchant CRM client list)
      // sees the latest picture without waiting for an Auth-state roundtrip.
      final pu = photoUrl?.trim() ?? '';
      if (pu.isNotEmpty) {
        update['photoUrl'] = pu;
      }

      // Ensure the merged document satisfies onboardingShapeValid(),
      // rolesShapeValid() and noLegacyDottedRoleKeys() in Firestore rules.
      // Older user docs may be missing or malformed on those fields, causing
      // every partial update() to be rejected with permission-denied.
      mergeUserPatchForFirestoreRules(existing, update);

      await userRef.set(update, SetOptions(merge: true));
      LoggerService.logInfo('Client basic info updated', context: {'uid': uid});
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(
            message:
                'Modification refusée. Reconnectez-vous et réessayez.',
          ),
        );
      }
      LoggerService.logError(
        'Error updating client basic info',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la mise à jour du profil',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
