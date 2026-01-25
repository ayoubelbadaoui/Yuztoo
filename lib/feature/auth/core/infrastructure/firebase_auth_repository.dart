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

      final profileDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final dto = AuthUserDto.fromFirebase(user, profileDoc: profileDoc);
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
  Stream<Result<AuthUser?>> watchAuthState() async* {
    await for (final user in _auth.userChanges()) {
      if (user == null) {
        yield const Right<AuthFailure, AuthUser?>(null);
        continue;
      }

      try {
        final profileDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final dto = AuthUserDto.fromFirebase(user, profileDoc: profileDoc);
        yield Right<AuthFailure, AuthUser?>(dto.toDomain());
      } on firebase.FirebaseAuthException catch (e, st) {
        yield Left<AuthFailure, AuthUser?>(_mapAuthException(e, st));
      } catch (e, st) {
        yield Left<AuthFailure, AuthUser?>(
            AuthUnexpectedFailure(cause: e, stackTrace: st));
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
