part of 'firebase_auth_repository.dart';

mixin _FirebaseAuthRepositoryPhone on _FirebaseAuthRepositoryBase {
  Future<Result<AuthUser>> verifyPhoneAndCreateUser({
    required String verificationId,
    required String smsCode,
    required EmailAddress email,
    required Password password,
  }) async {
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
        } on firebase.FirebaseAuthException catch (e) {
          // Firebase message: "User has already been linked to the given provider."
          // Code is typically: provider-already-linked
          if (e.code != 'provider-already-linked') rethrow;
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
      return Left<AuthFailure, AuthUser>(_mapSignupException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
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
