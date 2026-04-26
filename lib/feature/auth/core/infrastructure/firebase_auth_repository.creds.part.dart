part of 'firebase_auth_repository.dart';

mixin _FirebaseAuthRepositoryCreds on _FirebaseAuthRepositoryBase {
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.value,
        password: password.value,
      );

      final user = credential.user;
      if (user == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Utilisateur introuvable après la connexion.'),
        );
      }

      // Fetch Firestore profile with timeout to prevent hanging on slow networks
      // Use fallback if Firestore is slow or fails
      DocumentSnapshot<Map<String, dynamic>>? profileDoc;
      try {
        profileDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Timeout or error - use fallback (Firebase Auth user only)
        profileDoc = null;
      }

      final mapped = await _profileToAuthResult(user, profileDoc);
      if (mapped.isLeft) {
        return const Left<AuthFailure, AuthUser>(AccountDisabledFailure());
      }
      final authUser = mapped.rightOrNull;
      if (authUser == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Profil utilisateur introuvable.'),
        );
      }
      return Right<AuthFailure, AuthUser>(authUser);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, AuthUser>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  Future<Result<AuthUser>> signupWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.value,
        password: password.value,
      );

      final user = credential.user;
      if (user == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Utilisateur introuvable après l\'inscription.'),
        );
      }

      // Return AuthUser without Firestore profile (will be created later)
      final dto = AuthUserDto.fromFirebase(user);
      return Right<AuthFailure, AuthUser>(dto.toDomain());
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, AuthUser>(_mapSignupException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  Future<Result<String>> sendPhoneVerification({
    required String phoneNumber,
  }) async {
    final completer = Completer<Result<String>>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase.PhoneAuthCredential credential) {
          // Keep waiting for codeSent/timeout verificationId.
          // Completing with empty verificationId breaks OTP screen flow.
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          if (!completer.isCompleted) {
            // Check for billing errors specifically
            final errorMessage = e.message ?? '';
            if (errorMessage.contains('BILLING_NOT_ENABLED') ||
                errorMessage.toLowerCase().contains('billing')) {
              // ignore: prefer_const_constructors
              completer.complete(Left<AuthFailure, String>(
                const AuthUnexpectedFailure(
                  message:
                      'La vérification par SMS n\'est pas disponible pour le moment. Veuillez réessayer plus tard ou contacter le support.',
                ),
              ));
            } else {
              completer.complete(Left<AuthFailure, String>(
                _mapAuthException(e, StackTrace.current),
              ));
            }
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(Right<AuthFailure, String>(verificationId));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete(Right<AuthFailure, String>(verificationId));
          }
        },
      );

      return completer.future;
    } catch (e, st) {
      return Left<AuthFailure, String>(
        AuthUnexpectedFailure(cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<Unit>> verifyAndLinkPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final user = _auth.currentUser;
      if (user == null) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Aucun utilisateur connecté'),
        );
      }

      await user.linkWithCredential(credential);
      return const Right<AuthFailure, Unit>(unit);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, Unit>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  Future<Result<Unit>> sendPasswordResetEmail({
    required EmailAddress email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.value);
      return const Right<AuthFailure, Unit>(unit);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, Unit>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  Future<Result<Unit>> signOut() async {
    try {
      await _auth.signOut();
      return const Right<AuthFailure, Unit>(unit);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, Unit>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  Future<Result<AuthUser>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      // Note: accessToken requires explicit scope authorization in v7.
      // For Firebase auth, idToken alone is sufficient with null accessToken.
      final credential = firebase.GoogleAuthProvider.credential(
        idToken: idToken,
        // TODO: request oauth scopes via googleSignIn.authorizationClient if accessToken needed
      );
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(
              message: 'Utilisateur introuvable après connexion Google.'),
        );
      }
      DocumentSnapshot<Map<String, dynamic>>? profileDoc;
      try {
        profileDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        profileDoc = null;
      }
      final mapped = await _profileToAuthResult(user, profileDoc);
      if (mapped.isLeft) {
        return const Left<AuthFailure, AuthUser>(AccountDisabledFailure());
      }
      final authUser = mapped.rightOrNull;
      if (authUser == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Profil introuvable.'),
        );
      }
      return Right<AuthFailure, AuthUser>(authUser);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, AuthUser>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  Future<Result<AuthUser>> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = firebase.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCred = await _auth.signInWithCredential(oauthCredential);
      final user = userCred.user;
      if (user == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Utilisateur introuvable après connexion Apple.'),
        );
      }
      // Update display name from Apple credential if not set
      final firstName = appleCredential.givenName;
      final lastName = appleCredential.familyName;
      if (firstName != null && user.displayName == null) {
        await user.updateDisplayName('$firstName ${lastName ?? ''}'.trim());
      }
      DocumentSnapshot<Map<String, dynamic>>? profileDoc;
      try {
        profileDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        profileDoc = null;
      }
      final mapped = await _profileToAuthResult(user, profileDoc);
      if (mapped.isLeft) {
        return const Left<AuthFailure, AuthUser>(AccountDisabledFailure());
      }
      final authUser = mapped.rightOrNull;
      if (authUser == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Profil introuvable.'),
        );
      }
      return Right<AuthFailure, AuthUser>(authUser);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, AuthUser>(_mapAuthException(e, st));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Connexion Apple annulée.'),
        );
      }
      return Left<AuthFailure, AuthUser>(
        AuthUnexpectedFailure(message: e.message),
      );
    } catch (e, st) {
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  Future<Result<Unit>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Aucun utilisateur connecté'),
        );
      }
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      final trimmedPhoto = photoUrl?.trim();
      if (trimmedPhoto != null && trimmedPhoto.isNotEmpty) {
        await user.updatePhotoURL(trimmedPhoto);
      }
      return const Right<AuthFailure, Unit>(unit);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, Unit>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(cause: e, stackTrace: st),
      );
    }
  }
}
