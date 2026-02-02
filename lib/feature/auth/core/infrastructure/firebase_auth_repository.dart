import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../domain/auth_failure.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/value_objects/email_address.dart';
import '../domain/value_objects/password.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import 'dto/auth_user_dto.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required firebase.FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
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
          AuthUnexpectedFailure(message: 'User not found after sign-in.'),
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
      
      final dto = profileDoc != null && profileDoc.exists
          ? AuthUserDto.fromFirebase(user, profileDoc: profileDoc)
          : AuthUserDto.fromFirebase(user); // Fallback: use Firebase Auth data only
      return Right<AuthFailure, AuthUser>(dto.toDomain());
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, AuthUser>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
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
          AuthUnexpectedFailure(message: 'User not found after signup.'),
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

  @override
  Future<Result<String>> sendPhoneVerification({
    required String phoneNumber,
  }) async {
    final completer = Completer<Result<String>>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase.PhoneAuthCredential credential) {
          // Auto-verification completed on some devices
          if (!completer.isCompleted) {
            completer.complete(const Right<AuthFailure, String>(''));
          }
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
                  message: 'La vérification par SMS n\'est pas disponible pour le moment. Veuillez réessayer plus tard ou contacter le support.',
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

  @override
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

  @override
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

  @override
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

  @override
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
          AuthUnexpectedFailure(message: 'Échec de la vérification du téléphone'),
        );
      }

      // Link email/password to the phone-authenticated user
      final emailCredential = firebase.EmailAuthProvider.credential(
        email: email.value,
        password: password.value,
      );

      await phoneUser.linkWithCredential(emailCredential);

      // Get the updated user
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Utilisateur introuvable après la création'),
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

  @override
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

  @override
  Stream<Result<AuthUser?>> watchAuthState() async* {
    // Use userChanges() stream which automatically handles Firebase Auth persistence.
    // Root issue: on some devices/builds, userChanges() may not emit immediately on cold start,
    // which can leave the app stuck on splash waiting for the first auth state.
    //
    // Root fix: force an initial check with a short timeout, without emitting a false logout.
    // - If we have a currentUser -> emit immediately.
    // - If not, wait briefly for userChanges().first, then re-check currentUser before emitting null.
    String? lastEmittedUid;
    bool hasEmittedAny = false;

    firebase.User? initialUser = _auth.currentUser;
    if (initialUser == null) {
      try {
        initialUser = await _auth
            .userChanges()
            .first
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // No emission yet - re-check (Firebase may have restored session)
        initialUser = _auth.currentUser;
      } catch (_) {
        initialUser = _auth.currentUser;
      }

      // If we still look logged out, wait a tiny bit and re-check to avoid transient null.
      if (initialUser == null) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        initialUser = _auth.currentUser;
      }
    }

    // Emit initial state using the same mapping logic as the stream loop.
    // This guarantees the app won't get stuck on splash waiting for a first emission.
    lastEmittedUid = initialUser?.uid;
    hasEmittedAny = true;
    if (initialUser == null) {
      yield const Right<AuthFailure, AuthUser?>(null);
    } else {
      try {
        DocumentSnapshot<Map<String, dynamic>>? profileDoc;
        try {
          profileDoc = await _firestore
              .collection('users')
              .doc(initialUser.uid)
              .get()
              .timeout(const Duration(seconds: 5));
        } on TimeoutException {
          profileDoc = null;
        } catch (_) {
          profileDoc = null;
        }

        final dto = profileDoc != null && profileDoc.exists
            ? AuthUserDto.fromFirebase(initialUser, profileDoc: profileDoc)
            : AuthUserDto.fromFirebase(initialUser);
        yield Right<AuthFailure, AuthUser?>(dto.toDomain());
      } catch (_) {
        // Any error while building the initial user -> fallback to FirebaseAuth user only
        final dto = AuthUserDto.fromFirebase(initialUser);
        yield Right<AuthFailure, AuthUser?>(dto.toDomain());
      }
    }
    
    await for (final userEvent in _auth.userChanges()) {
      // ROOT FIX:
      // FirebaseAuth.userChanges() can transiently emit `null` during token refresh,
      // app lifecycle transitions, or provider initialization.
      // If Firebase still has a non-null currentUser, we should NOT emit an
      // unauthenticated state (it causes UI "logout flicker").
      final user = userEvent ?? _auth.currentUser;

      // Skip duplicate emissions: same uid as last emitted (prevents duplicate emits)
      // But allow: null -> user, user -> null, or user -> different user
      final newUid = user?.uid;
      if (hasEmittedAny && newUid == lastEmittedUid) {
        continue;
      }
      lastEmittedUid = newUid;
      hasEmittedAny = true;
      
      if (user == null) {
        yield const Right<AuthFailure, AuthUser?>(null);
        continue;
      }

      try {
        // Try to fetch Firestore profile with timeout to handle delays gracefully
        // If Firestore is slow or fails, use fallback data from Firebase Auth user
        DocumentSnapshot<Map<String, dynamic>>? profileDoc;
        try {
          profileDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 5));
        } on TimeoutException {
          // Timeout is not an error - just use fallback data
          profileDoc = null;
        } catch (e) {
          // Any Firestore error - use fallback data
          profileDoc = null;
        }
        
        // Use profile doc if available, otherwise create DTO from Firebase Auth user only
        final dto = profileDoc != null && profileDoc.exists
            ? AuthUserDto.fromFirebase(user, profileDoc: profileDoc)
            : AuthUserDto.fromFirebase(user); // Fallback: use Firebase Auth data only
        
        yield Right<AuthFailure, AuthUser?>(dto.toDomain());
      } on firebase.FirebaseAuthException catch (e) {
        // Only yield error for actual auth errors, not Firestore delays
        // For Firestore issues, use fallback data
        if (e.code == 'network-request-failed') {
          // Network error - use fallback data from Firebase Auth
          final dto = AuthUserDto.fromFirebase(user);
          yield Right<AuthFailure, AuthUser?>(dto.toDomain());
        } else {
          yield Left<AuthFailure, AuthUser?>(_mapAuthException(e, StackTrace.current));
        }
      } catch (e) {
        // Any other error (including Firestore timeouts/errors) - use fallback
        // Don't show errors for Firestore delays, just use Firebase Auth data
        final dto = AuthUserDto.fromFirebase(user);
        yield Right<AuthFailure, AuthUser?>(dto.toDomain());
      }
    }
  }

  AuthFailure _mapAuthException(
      firebase.FirebaseAuthException error, StackTrace stackTrace) {
    switch (error.code) {
      case 'user-disabled':
        return const AccountDisabledFailure();
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        // All invalid credential errors should show "Identifiants invalides"
        return const InvalidCredentialsFailure();
      case 'network-request-failed':
        return AuthNetworkFailure(cause: error, stackTrace: stackTrace);
      case 'user-cancelled':
        return const UserCancelledFailure();
      case 'internal-error':
        // Check if it's a billing error
        if (error.message?.contains('BILLING_NOT_ENABLED') == true ||
            error.message?.toLowerCase().contains('billing') == true) {
          return const AuthUnexpectedFailure(
            message: 'La vérification par SMS n\'est pas disponible pour le moment. Veuillez réessayer plus tard ou contacter le support.',
          );
        }
        return AuthUnexpectedFailure(cause: error, stackTrace: stackTrace);
      default:
        // Check error message for invalid credential keywords (fallback for edge cases)
        if (error.message?.toLowerCase().contains('invalid') == true ||
            error.message?.toLowerCase().contains('credential') == true ||
            error.message?.toLowerCase().contains('password') == true) {
          return const InvalidCredentialsFailure();
        }
        // Check error message for billing-related errors
        if (error.message?.contains('BILLING_NOT_ENABLED') == true ||
            error.message?.toLowerCase().contains('billing') == true) {
          return const AuthUnexpectedFailure(
            message: 'La vérification par SMS n\'est pas disponible pour le moment. Veuillez réessayer plus tard ou contacter le support.',
          );
        }
        return AuthUnexpectedFailure(cause: error, stackTrace: stackTrace);
    }
  }

  AuthFailure _mapSignupException(
      firebase.FirebaseAuthException error, StackTrace stackTrace) {
    switch (error.code) {
      case 'email-already-in-use':
        return const AuthUnexpectedFailure(
            message: 'Cette adresse email est déjà utilisée');
      case 'weak-password':
        return const AuthUnexpectedFailure(
            message: 'Le mot de passe est trop faible');
      case 'invalid-email':
        return const AuthUnexpectedFailure(
            message: 'Adresse email invalide');
      case 'phone-number-already-exists':
      case 'credential-already-in-use':
        return const AuthUnexpectedFailure(
            message: 'Ce numéro de téléphone est déjà utilisé');
      case 'invalid-verification-code':
        return const AuthUnexpectedFailure(
            message: 'Code de vérification invalide');
      case 'network-request-failed':
        return AuthNetworkFailure(cause: error, stackTrace: stackTrace);
      default:
        return AuthUnexpectedFailure(cause: error, stackTrace: stackTrace);
    }
  }
}
