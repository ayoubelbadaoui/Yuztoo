part of 'firebase_auth_repository.dart';

mixin _FirebaseAuthRepositoryPhone on _FirebaseAuthRepositoryBase {
  Future<Result<AuthUser>> verifyPhoneAndCreateUser({
    required String verificationId,
    required String smsCode,
    required EmailAddress email,
    required Password password,
  }) async {
    // We may need to roll back a freshly-created phone user if email linking
    // fails — without this, the phone (and any half-linked email) stays
    // claimed in Firebase Auth and blocks reuse on the next signup attempt.
    bool createdPhoneUserInThisCall = false;
    bool linkedEmailInThisCall = false;
    firebase.User? createdPhoneUser;

    try {
      // First verify the phone number
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with phone credential
      final phoneCredential = await _auth.signInWithCredential(credential);
      final phoneUser = phoneCredential.user;

      if (phoneUser == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(
              message: 'Échec de la vérification du téléphone'),
        );
      }

      // Track whether this call brought the user into Firebase Auth.
      // `isNewUser` is true the first time a phone credential signs in;
      // subsequent OTPs on the same phone return false (existing user).
      // Only the new-user branch is safe to delete on failure — never
      // touch a user that pre-existed in Firebase Auth.
      createdPhoneUserInThisCall =
          phoneCredential.additionalUserInfo?.isNewUser ?? false;
      createdPhoneUser = phoneUser;

      // If this phone is already tied to an existing profile, block signup:
      // one phone number must map to one account only.
      // On transient Firestore issues, continue and let createUserDocument()
      // enforce phone_index ownership.
      DocumentSnapshot<Map<String, dynamic>>? existingProfile;
      try {
        existingProfile = await _firestore
            .collection('users')
            .doc(phoneUser.uid)
            .get()
            .timeout(const Duration(seconds: 5));
      } on TimeoutException catch (_) {
        LoggerService.logError(
          'verifyPhoneAndCreateUser: timeout reading users/{uid}; continuing',
          context: {'uid': phoneUser.uid},
        );
      } catch (e, st) {
        LoggerService.logError(
          'verifyPhoneAndCreateUser: error reading users/{uid}; continuing',
          error: e,
          stackTrace: st,
          context: {'uid': phoneUser.uid},
        );
      }
      if (existingProfile?.exists == true) {
        try {
          await _auth.signOut();
        } catch (_) {}
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(
            message:
                'Vous avez déjà un compte avec ce numéro — nous ne créons pas deux comptes pour le même numéro. Connectez-vous.',
          ),
        );
      }

      // Link email/password to the phone-authenticated user (idempotent).
      // If the user retries OTP verification, the provider may already be linked.
      final alreadyHasPasswordProvider = phoneUser.providerData.any(
        (p) => p.providerId == 'password',
      );
      if (!alreadyHasPasswordProvider) {
        final emailCredential = firebase.EmailAuthProvider.credential(
          email: email.value,
          password: password.value,
        );
        try {
          await phoneUser.linkWithCredential(emailCredential);
          linkedEmailInThisCall = true;
        } on firebase.FirebaseAuthException catch (e) {
          // Firebase message: "User has already been linked to the given provider."
          // Code is typically: provider-already-linked
          if (e.code != 'provider-already-linked') {
            // Rollback the phone user we just created so the phone (and any
            // partial email link from a parallel attempt) is released. Without
            // this, a failed `email-already-in-use` link would leave the phone
            // claimed and any subsequent signup with the same phone or email
            // would be blocked even after the user "starts over".
            await _rollbackOrphanSignupUser(
              createdInThisCall: createdPhoneUserInThisCall,
              linkedEmailInThisCall: false,
              user: createdPhoneUser,
            );
            rethrow;
          }
        }
      }

      // Get the updated user
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(
              message: 'Utilisateur introuvable après la création'),
        );
      }

      // Return AuthUser without Firestore profile (will be created later)
      final dto = AuthUserDto.fromFirebase(updatedUser);
      return Right<AuthFailure, AuthUser>(dto.toDomain());
    } on firebase.FirebaseAuthException catch (e, st) {
      // Defensive rollback: any FirebaseAuthException after we created the
      // phone user (e.g. linkWithCredential rethrow above, or anything else
      // surfaced during the link step) must release the phone slot.
      await _rollbackOrphanSignupUser(
        createdInThisCall: createdPhoneUserInThisCall,
        linkedEmailInThisCall: linkedEmailInThisCall,
        user: createdPhoneUser,
      );
      return Left<AuthFailure, AuthUser>(_mapSignupException(e, st));
    } catch (e, st) {
      await _rollbackOrphanSignupUser(
        createdInThisCall: createdPhoneUserInThisCall,
        linkedEmailInThisCall: linkedEmailInThisCall,
        user: createdPhoneUser,
      );
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  /// Best-effort cleanup of a Firebase Auth user that was created mid-signup
  /// but never reached a persisted Firestore profile.
  ///
  /// Intentionally conservative: only deletes when the same call created the
  /// user. A pre-existing user (recovery path / legitimate retry) is left
  /// alone — deleting it would destroy a real account in case of partial
  /// migrations or concurrent flows. When deletion is not safe we still
  /// `signOut` so the shell does not boot the orphan as a logged-in session.
  Future<void> _rollbackOrphanSignupUser({
    required bool createdInThisCall,
    required bool linkedEmailInThisCall,
    required firebase.User? user,
  }) async {
    if (user == null) {
      return;
    }
    if (!createdInThisCall && !linkedEmailInThisCall) {
      // We did not introduce any state — leave the existing user as-is and
      // just sign out to keep the shell from booting them with no profile.
      try {
        if (_auth.currentUser != null) {
          await _auth.signOut();
        }
      } catch (_) {}
      return;
    }
    try {
      await user.delete();
    } catch (e, st) {
      LoggerService.logError(
        'verifyPhoneAndCreateUser: rollback delete failed; signing out',
        error: e,
        stackTrace: st,
        context: {'uid': user.uid},
      );
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  Future<Result<Unit>> deleteCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Aucun utilisateur connecté'),
        );
      }

      await user.delete();
      return const Right<AuthFailure, Unit>(unit);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, Unit>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }
}
