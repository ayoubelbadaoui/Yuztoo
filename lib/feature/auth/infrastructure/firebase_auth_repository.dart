import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../domain/auth_failure.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/value_objects/email_address.dart';
import '../domain/value_objects/password.dart';
import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/result.dart';
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

  @override
  Future<Result<AuthUser>> createUserWithEmailAndPassword({
    required EmailAddress email,
    required Password password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value,
      );

      final user = credential.user;
      if (user == null) {
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'User not found after sign-up.'),
        );
      }

      // Try to fetch profile doc, but it might not exist yet for new users
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
  Future<Result<String>> sendPhoneVerification({
    required String phoneNumber,
  }) async {
    try {
      final completer = Completer<String>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase.PhoneAuthCredential credential) {
          // Auto-verification completed on some devices
          if (!completer.isCompleted) {
            // We still return a fake verificationId since code is auto verified
            completer.complete('');
          }
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );

      final verificationId = await completer.future;
      return Right<AuthFailure, String>(verificationId);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, String>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, String>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<Unit>> linkPhoneCredential({
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
          AuthUnexpectedFailure(message: 'No user is currently signed in.'),
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

  AuthFailure _mapAuthException(
      firebase.FirebaseAuthException error, StackTrace stackTrace) {
    switch (error.code) {
      case 'user-disabled':
        return const AccountDisabledFailure();
      case 'user-not-found':
      case 'wrong-password':
        return const InvalidCredentialsFailure();
      case 'email-already-in-use':
      case 'weak-password':
      case 'invalid-email':
        return AuthUnexpectedFailure(
          message: error.message ?? 'Authentication error occurred.',
          cause: error,
          stackTrace: stackTrace,
        );
      case 'network-request-failed':
        return AuthNetworkFailure(cause: error, stackTrace: stackTrace);
      case 'user-cancelled':
        return const UserCancelledFailure();
      case 'invalid-verification-code':
      case 'invalid-verification-id':
      case 'phone-number-already-exists':
      case 'credential-already-in-use':
      case 'provider-already-linked':
      case 'invalid-phone-number':
        return AuthUnexpectedFailure(
          message: error.message ?? 'Phone verification error occurred.',
          cause: error,
          stackTrace: stackTrace,
        );
      default:
        return AuthUnexpectedFailure(cause: error, stackTrace: stackTrace);
    }
  }
}
