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
            } else if (e.code == 'app-not-authorized' ||
                errorMessage.contains('INVALID_CERT_HASH') ||
                errorMessage.contains('missing client identifier') ||
                errorMessage.contains('package certificate hash')) {
              completer.complete(const Left<AuthFailure, String>(
                AuthUnexpectedFailure(
                  message:
                      'L\'application n\'est pas autorisée (certificat SHA-1 manquant dans la console Firebase). Contactez le support.',
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
      if (idToken == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(
            message:
                'Erreur de configuration Google Sign-In. Veuillez réessayer.',
          ),
        );
      }
      final credential = firebase.GoogleAuthProvider.credential(
        idToken: idToken,
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
    } on PlatformException catch (e) {
      // Error code 10 = DEVELOPER_ERROR (SHA-1 / OAuth client misconfiguration)
      // Error code 12501 / "sign_in_canceled" = user cancelled
      if (e.code == '12501' ||
          e.message?.toLowerCase().contains('cancel') == true) {
        return const Left<AuthFailure, AuthUser>(
          UserCancelledFailure(),
        );
      }
      return Left<AuthFailure, AuthUser>(
        AuthUnexpectedFailure(
          message: e.message ?? 'Erreur Google Sign-In (${e.code}).',
          cause: e,
        ),
      );
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

  Future<Result<AuthUser>> linkWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Aucun utilisateur connecté'),
        );
      }
      // If already linked, return the current user as-is.
      final alreadyLinked = user.providerData
          .any((p) => p.providerId == 'google.com');
      if (alreadyLinked) {
        final dto = AuthUserDto.fromFirebase(user);
        return Right<AuthFailure, AuthUser>(dto.toDomain());
      }

      final googleSignIn = GoogleSignIn.instance;
      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(
            message: 'Impossible d\'obtenir le token Google. Réessayez.',
          ),
        );
      }
      final credential = firebase.GoogleAuthProvider.credential(idToken: idToken);
      await user.linkWithCredential(credential);
      // Refresh to get updated providerData.
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Utilisateur introuvable après liaison.'),
        );
      }
      final dto = AuthUserDto.fromFirebase(refreshed);
      return Right<AuthFailure, AuthUser>(dto.toDomain());
    } on firebase.FirebaseAuthException catch (e, st) {
      if (e.code == 'provider-already-linked' ||
          e.code == 'credential-already-in-use') {
        final user = _auth.currentUser;
        if (user != null) {
          final dto = AuthUserDto.fromFirebase(user);
          return Right<AuthFailure, AuthUser>(dto.toDomain());
        }
      }
      return Left<AuthFailure, AuthUser>(_mapAuthException(e, st));
    } on PlatformException catch (e) {
      if (e.code == '12501' ||
          e.message?.toLowerCase().contains('cancel') == true) {
        return const Left<AuthFailure, AuthUser>(UserCancelledFailure());
      }
      return Left<AuthFailure, AuthUser>(
        AuthUnexpectedFailure(
          message: e.message ?? 'Erreur Google Sign-In (${e.code}).',
          cause: e,
        ),
      );
    } catch (e, st) {
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  List<String> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];
    return user.providerData.map((p) => p.providerId).toList();
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
