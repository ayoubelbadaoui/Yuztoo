part of 'firebase_user_repository.dart';

mixin _FirebaseUserRepositoryWrites on _FirebaseUserRepositoryBase {
  Future<Result<Unit>> markMerchantOnboardingCompleted(String uid) async {
    try {
      // Read-then-write to preserve any existing `onboarding.client` value.
      // The previous code wrote `{'onboarding': {'merchant': 'completed'}}`
      // with merge:true — Firestore does NOT deep-merge nested maps under
      // merge:true, so the entire onboarding map was being replaced with
      // a {merchant} singleton, silently dropping the client field for
      // every dual-profile user. After that, isClientOnboardingCompleted
      // returned false (key missing) and the next routing pass dumped the
      // dual-profile user back into client onboarding.
      final ref = _firestore.collection('users').doc(uid);
      final snap = await ref.get();
      final existingOnboarding = Map<String, dynamic>.from(
        (snap.data()?['onboarding'] as Map<String, dynamic>?) ?? {},
      );
      existingOnboarding['merchant'] = 'completed';
      existingOnboarding.putIfAbsent('client', () => 'not_started');
      await ref.set(
        <String, dynamic>{
          'onboarding': existingOnboarding,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      LoggerService.logError(
        'Error marking merchant onboarding completed',
        error: e,
        stackTrace: st,
        context: {'uid': uid},
      );
      return const Right<AuthFailure, Unit>(unit);
    }
  }

  Future<Result<Unit>> patchUserDocument(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final doc = await userRef.get();
      if (!doc.exists) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Le document utilisateur est introuvable.'),
        );
      }

      final data = doc.data();
      if (data == null) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Données utilisateur absentes.'),
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
          // Legacy cleanup: existing users skip client onboarding gate.
          'client': 'completed',
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

      // Normalize onboarding marker for legacy users (merge; do not drop client).
      final merchantId = (data['merchant_id'] as String?)?.trim();
      final currentOnboarding = data['onboarding'] as Map<String, dynamic>?;
      final currentMerchantStatus =
          (currentOnboarding?['merchant'] as String?)?.trim().toLowerCase();
      final targetMerchantStatus = (merchantId != null && merchantId.isNotEmpty)
          ? 'completed'
          : 'not_started';
      final mergedOnboarding =
          Map<String, dynamic>.from(currentOnboarding ?? {});
      var onboardingDirty = false;
      if (currentMerchantStatus != targetMerchantStatus) {
        mergedOnboarding['merchant'] = targetMerchantStatus;
        onboardingDirty = true;
      }
      if (!mergedOnboarding.containsKey('client')) {
        mergedOnboarding['client'] = 'completed';
        onboardingDirty = true;
      }
      if (onboardingDirty) {
        updates['onboarding'] = mergedOnboarding;
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

  Future<Result<Unit>> updateLastLoginAt(
    String uid, {
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final update = <String, dynamic>{
        'last_login_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      // Mirror Firebase Auth → Firestore on every sign-in so the merchant
      // CRM client list always shows the latest photo/name without waiting
      // for the user to re-edit their personal info. Backfills accounts that
      // were created before the avatar-mirror code shipped.
      final dn = displayName?.trim() ?? '';
      if (dn.isNotEmpty) {
        update['displayName'] = dn;
      }
      final pu = photoUrl?.trim() ?? '';
      if (pu.isNotEmpty) {
        update['photoUrl'] = pu;
      }
      await _firestore.collection('users').doc(uid).update(update);
      LoggerService.logInfo('Last login timestamp updated successfully',
          context: {
            'uid': uid,
            'mirroredPhoto': pu.isNotEmpty,
            'mirroredName': dn.isNotEmpty,
          });
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

  Future<Result<bool>> isPhoneNumberRegistered(String phone) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      return const Right<AuthFailure, bool>(false);
    }
    try {
      final snap = await _firestore
          .collection('phone_index')
          .doc(normalizedPhone)
          .get();
      return Right<AuthFailure, bool>(snap.exists);
    } catch (e, st) {
      LoggerService.logError(
        'Error checking phone_index',
        error: e,
        stackTrace: st,
        context: {'phone': normalizedPhone},
      );
      return Left<AuthFailure, bool>(
        AuthUnexpectedFailure(
          message:
              'Impossible de vérifier le numéro. Vérifiez votre connexion et réessayez.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Result<bool>> isEmailRegistered(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return const Right<AuthFailure, bool>(false);
    }
    try {
      final snap = await _firestore
          .collection('email_index')
          .doc(normalizedEmail)
          .get();
      if (snap.exists) {
        return const Right<AuthFailure, bool>(true);
      }
    } catch (e, st) {
      LoggerService.logError(
        'Error checking email_index',
        error: e,
        stackTrace: st,
        context: {'email': normalizedEmail},
      );
      return Left<AuthFailure, bool>(
        AuthUnexpectedFailure(
          message:
              'Impossible de vérifier l\'adresse e-mail. Vérifiez votre connexion et réessayez.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
    // Firebase Auth 6+ removed fetchSignInMethodsForEmail (email enumeration).
    // Registered emails are tracked in Firestore `email_index` above.
    return const Right<AuthFailure, bool>(false);
  }

  Future<Result<Unit>> addSecondaryClientRole(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final onboarding = Map<String, dynamic>.from(
          (data['onboarding'] as Map<String, dynamic>?) ?? {});
      // Use update() so dotted keys are treated as nested field paths,
      // not literal top-level keys (which would violate noLegacyDottedRoleKeys rule).
      final updates = <String, dynamic>{
        'roles.client': true,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (!onboarding.containsKey('client')) {
        updates['onboarding.client'] = 'not_started';
      }
      await userRef.update(updates);
      LoggerService.logInfo('Secondary client role added', context: {'uid': uid});
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      LoggerService.logError('Error adding secondary client role',
          error: e, stackTrace: st, context: {'uid': uid});
      return Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: e.toString(), cause: e, stackTrace: st));
    }
  }

  Future<Result<Unit>> addSecondaryMerchantRole(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final onboarding = Map<String, dynamic>.from(
          (data['onboarding'] as Map<String, dynamic>?) ?? {});
      // Use update() so dotted keys are treated as nested field paths.
      final updates = <String, dynamic>{
        'roles.merchant': true,
        'roles.provider': true,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (!onboarding.containsKey('merchant')) {
        updates['onboarding.merchant'] = 'not_started';
      }
      await userRef.update(updates);
      LoggerService.logInfo('Secondary merchant role added', context: {'uid': uid});
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      LoggerService.logError('Error adding secondary merchant role',
          error: e, stackTrace: st, context: {'uid': uid});
      return Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: e.toString(), cause: e, stackTrace: st));
    }
  }
}
