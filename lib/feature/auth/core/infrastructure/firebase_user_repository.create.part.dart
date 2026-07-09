part of 'firebase_user_repository.dart';

mixin _FirebaseUserRepositoryCreate on _FirebaseUserRepositoryBase {
  Future<Result<Unit>> createUserDocument({
    required String uid,
    required String email,
    required String phone,
    required Map<String, bool> roles,
    String city = '',
    String? firstName,
    String? lastName,
    String? displayName,
    String? photoUrl,
  }) async {
    // City is now optional at signup — merchants set it during onboarding.
    final persistedCity = city.trim().isEmpty ? null : CityInput.forFirestore(city);

    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      // Phone is optional at signup (App Store Guideline 5.1.1).
    }

    const duplicateMsg = AuthUnexpectedFailure(
      message:
          'Vous avez déjà un compte avec ce numéro — nous ne créons pas deux comptes pour le même numéro. Connectez-vous.',
    );

    final fn = firstName?.trim() ?? '';
    final ln = lastName?.trim() ?? '';
    final dn = displayName?.trim() ?? '';
    final pu = photoUrl?.trim() ?? '';

    Map<String, dynamic> userPayload() => {
          'uid': uid,
          'email': email,
          if (normalizedPhone.isNotEmpty) 'phone': normalizedPhone,
          'roles': roles,
          'primary_role': roles['merchant'] == true ? 'merchant' : 'client',
          if (persistedCity != null) 'city': persistedCity,
          if (fn.isNotEmpty) 'firstName': fn,
          if (ln.isNotEmpty) 'lastName': ln,
          if (dn.isNotEmpty) 'displayName': dn,
          if (pu.isNotEmpty) 'photoUrl': pu,
          'merchant_id': null,
          // BOTH flags start as 'not_started' for new signups. Pre-setting
          // the inactive role's flag to 'completed' was the auto-complete
          // bug: a client who signs up and later taps "créer un compte
          // pro" would have isMerchantOnboardingCompleted return true (from
          // this stale 'completed' marker) and be skipped past merchant
          // onboarding into an empty storefront with no merchant doc. The
          // correct semantics is "haven't done it yet" for any role the
          // user has not actually onboarded through, regardless of whether
          // they currently hold that role.
          'onboarding': {
            'merchant': 'not_started',
            'client': 'not_started',
          },
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_login_at': null,
          'force_merchant_next_login': roles['merchant'] == true,
        };

    const duplicateEmailMsg = AuthUnexpectedFailure(
      message:
          'Cette adresse e-mail est déjà utilisée. Connectez-vous ou utilisez une autre adresse.',
    );

    final normalizedEmail = email.trim().toLowerCase();

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(uid);
        final phoneIndexRef = normalizedPhone.isNotEmpty
            ? _firestore.collection('phone_index').doc(normalizedPhone)
            : null;
        final emailIndexRef =
            _firestore.collection('email_index').doc(normalizedEmail);

        // All reads must come before any writes in a Firestore transaction.
        final userSnap = await transaction.get(userRef);
        final phoneSnap = phoneIndexRef != null
            ? await transaction.get(phoneIndexRef)
            : null;
        final emailSnap = await transaction.get(emailIndexRef);

        // --- Checks ---
        if (userSnap.exists) {
          throw const DuplicatePhoneIndexException();
        }

        // For phone_index / email_index: any existing doc means the slot is
        // claimed. We must treat orphan rows (uid missing or empty) as
        // claimed too — silently letting them through used to create a user
        // whose phone_index / email_index pointed nowhere, allowing a third
        // party to subsequently re-claim the same identifier. The
        // upstream `verifyPhoneAvailableForSignup` / `verifyEmailAvailableForSignup`
        // calls block these cases at the form layer; this in-transaction
        // check is the second line of defence.
        if (phoneSnap != null && phoneSnap.exists) {
          final existingUid = (phoneSnap.data()?['uid'] as String?)?.trim();
          if (existingUid == null || existingUid.isEmpty) {
            LoggerService.logError(
              'createUserDocument: orphan phone_index detected (uid missing); '
              'treating as duplicate to avoid silent re-claim',
              context: {'phone': normalizedPhone, 'requestUid': uid},
            );
            throw const DuplicatePhoneIndexException();
          }
          if (existingUid != uid) {
            throw const DuplicatePhoneIndexException();
          }
        }

        if (emailSnap.exists) {
          final existingUid = (emailSnap.data()?['uid'] as String?)?.trim();
          if (existingUid == null || existingUid.isEmpty) {
            LoggerService.logError(
              'createUserDocument: orphan email_index detected (uid missing); '
              'treating as duplicate to avoid silent re-claim',
              context: {'email': normalizedEmail, 'requestUid': uid},
            );
            throw const DuplicateEmailIndexException();
          }
          if (existingUid != uid) {
            throw const DuplicateEmailIndexException();
          }
        }

        // --- Writes (only after all reads) ---
        if (phoneIndexRef != null && phoneSnap != null && !phoneSnap.exists) {
          transaction.set(phoneIndexRef, {'uid': uid});
        }
        if (!emailSnap.exists) {
          transaction.set(emailIndexRef, {'uid': uid});
        }
        transaction.set(userRef, userPayload(), SetOptions(merge: false));
      });

      LoggerService.logInfo('User document created successfully',
          context: {'uid': uid, 'email': email, 'city': persistedCity});
      return const Right<AuthFailure, Unit>(unit);
    } on DuplicatePhoneIndexException {
      return const Left<AuthFailure, Unit>(duplicateMsg);
    } on DuplicateEmailIndexException {
      return const Left<AuthFailure, Unit>(duplicateEmailMsg);
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
              context: {'uid': uid, 'email': email, 'city': persistedCity});
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
        context: {'uid': uid, 'email': email, 'phone': phone, 'city': persistedCity},
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
}
