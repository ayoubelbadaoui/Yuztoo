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
import '../../../../core/infrastructure/logger_service.dart';
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
        LoggerService.logFailure(
          'AuthFailure',
          'User not found after sign-in',
          context: {'email': email.value},
        );
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'User not found after sign-in.'),
        );
      }

      final profileDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final dto = AuthUserDto.fromFirebase(user, profileDoc: profileDoc);
      LoggerService.logInfo('Sign-in successful', context: {'uid': user.uid, 'email': email.value});
      return Right<AuthFailure, AuthUser>(dto.toDomain());
    } on firebase.FirebaseAuthException catch (e, st) {
      LoggerService.logError(
        'FirebaseAuthException during sign-in',
        error: e,
        stackTrace: st,
        context: {'code': e.code, 'email': email.value},
      );
      return Left<AuthFailure, AuthUser>(_mapAuthException(e, st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error during sign-in',
        error: e,
        stackTrace: st,
        context: {'email': email.value},
      );
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
        LoggerService.logFailure(
          'AuthFailure',
          'User not found after signup',
          context: {'email': email.value},
        );
        return const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'User not found after signup.'),
        );
      }

      // Return AuthUser without Firestore profile (will be created later)
      final dto = AuthUserDto.fromFirebase(user);
      LoggerService.logInfo('Signup successful', context: {'uid': user.uid, 'email': email.value});
      return Right<AuthFailure, AuthUser>(dto.toDomain());
    } on firebase.FirebaseAuthException catch (e, st) {
      LoggerService.logError(
        'FirebaseAuthException during signup',
        error: e,
        stackTrace: st,
        context: {'code': e.code, 'email': email.value},
      );
      return Left<AuthFailure, AuthUser>(_mapSignupException(e, st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error during signup',
        error: e,
        stackTrace: st,
        context: {'email': email.value},
      );
      return Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<String>> sendPhoneVerification({
    required String phoneNumber,
  }) async {
    final completer = Completer<Result<String>>();
    const autoVerificationId = '__auto__';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          // Auto-verification completed on some devices
          try {
            final user = _auth.currentUser;
            if (user == null) {
              if (!completer.isCompleted) {
                completer.complete(const Left<AuthFailure, String>(
                  AuthUnexpectedFailure(message: 'Aucun utilisateur connecté'),
                ));
              }
              return;
            }

            await user.linkWithCredential(credential);
            LoggerService.logInfo(
              'Phone auto-verified and linked',
              context: {'uid': user.uid, 'phoneNumber': phoneNumber},
            );
            if (!completer.isCompleted) {
              completer.complete(const Right<AuthFailure, String>(autoVerificationId));
            }
          } on firebase.FirebaseAuthException catch (e, st) {
            LoggerService.logError(
              'FirebaseAuthException during auto phone linking',
              error: e,
              stackTrace: st,
              context: {'code': e.code, 'phoneNumber': phoneNumber},
            );
            if (!completer.isCompleted) {
              completer.complete(Left<AuthFailure, String>(_mapAuthException(e, st)));
            }
          } catch (e, st) {
            LoggerService.logError(
              'Unexpected error during auto phone linking',
              error: e,
              stackTrace: st,
              context: {'phoneNumber': phoneNumber},
            );
            if (!completer.isCompleted) {
              completer.complete(Left<AuthFailure, String>(
                AuthUnexpectedFailure(cause: e, stackTrace: st),
              ));
            }
          }
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          LoggerService.logError(
            'Phone verification failed',
            error: e,
            stackTrace: StackTrace.current,
            context: {'code': e.code, 'phoneNumber': phoneNumber},
          );
          if (!completer.isCompleted) {
            completer.complete(Left<AuthFailure, String>(
              _mapAuthException(e, StackTrace.current),
            ));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          LoggerService.logInfo('Phone verification code sent', context: {'phoneNumber': phoneNumber});
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
      LoggerService.logError(
        'Unexpected error during phone verification',
        error: e,
        stackTrace: st,
        context: {'phoneNumber': phoneNumber},
      );
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
        LoggerService.logFailure(
          'AuthFailure',
          'No authenticated user when linking phone',
          context: {'verificationId': verificationId},
        );
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Aucun utilisateur connecté'),
        );
      }

      await user.linkWithCredential(credential);
      LoggerService.logInfo('Phone linked successfully', context: {'uid': user.uid});
      return const Right<AuthFailure, Unit>(unit);
    } on firebase.FirebaseAuthException catch (e, st) {
      LoggerService.logError(
        'FirebaseAuthException during phone linking',
        error: e,
        stackTrace: st,
        context: {'code': e.code, 'verificationId': verificationId},
      );
      return Left<AuthFailure, Unit>(_mapAuthException(e, st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error during phone linking',
        error: e,
        stackTrace: st,
        context: {'verificationId': verificationId},
      );
      return Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<Unit>> deleteCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        LoggerService.logFailure(
          'AuthFailure',
          'No authenticated user to delete',
        );
        return const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Aucun utilisateur connecté'),
        );
      }

      await user.delete();
      LoggerService.logInfo('User deleted successfully', context: {'uid': user.uid});
      return const Right<AuthFailure, Unit>(unit);
    } on firebase.FirebaseAuthException catch (e, st) {
      LoggerService.logError(
        'FirebaseAuthException during deleteCurrentUser',
        error: e,
        stackTrace: st,
        context: {'code': e.code},
      );
      return Left<AuthFailure, Unit>(_mapAuthException(e, st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error during deleteCurrentUser',
        error: e,
        stackTrace: st,
      );
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<Unit>> signOut() async {
    try {
      await _auth.signOut();
      LoggerService.logInfo('Sign out successful');
      return const Right<AuthFailure, Unit>(unit);
    } on firebase.FirebaseAuthException catch (e, st) {
      LoggerService.logError(
        'FirebaseAuthException during sign out',
        error: e,
        stackTrace: st,
        context: {'code': e.code},
      );
      return Left<AuthFailure, Unit>(_mapAuthException(e, st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error during sign out',
        error: e,
        stackTrace: st,
      );
      return Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Stream<Result<AuthUser?>> watchAuthState() async* {
    // Emit current user immediately (root fix - don't wait for stream)
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final profileDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        final dto = AuthUserDto.fromFirebase(currentUser, profileDoc: profileDoc);
        yield Right<AuthFailure, AuthUser?>(dto.toDomain());
      } on firebase.FirebaseAuthException catch (e, st) {
        LoggerService.logError(
          'FirebaseAuthException in watchAuthState (current user)',
          error: e,
          stackTrace: st,
          context: {'code': e.code, 'uid': currentUser.uid},
        );
        yield Left<AuthFailure, AuthUser?>(_mapAuthException(e, st));
      } catch (e, st) {
        LoggerService.logError(
          'Unexpected error in watchAuthState (current user)',
          error: e,
          stackTrace: st,
          context: {'uid': currentUser.uid},
        );
        yield Left<AuthFailure, AuthUser?>(
            AuthUnexpectedFailure(cause: e, stackTrace: st));
      }
    } else {
      // No current user - emit null immediately
      yield const Right<AuthFailure, AuthUser?>(null);
    }

    // Then listen to changes
    await for (final user in _auth.userChanges()) {
      // Skip if it's the same as current user we already emitted
      if (user?.uid == currentUser?.uid) {
        continue;
      }

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
        LoggerService.logError(
          'FirebaseAuthException in watchAuthState',
          error: e,
          stackTrace: st,
          context: {'code': e.code, 'uid': user.uid},
        );
        yield Left<AuthFailure, AuthUser?>(_mapAuthException(e, st));
      } catch (e, st) {
        LoggerService.logError(
          'Unexpected error in watchAuthState',
          error: e,
          stackTrace: st,
          context: {'uid': user.uid},
        );
        yield Left<AuthFailure, AuthUser?>(
            AuthUnexpectedFailure(cause: e, stackTrace: st));
      }
    }
  }

  AuthFailure _mapAuthException(
      firebase.FirebaseAuthException error, StackTrace stackTrace) {
    final failure = _mapAuthExceptionInternal(error, stackTrace);
    LoggerService.logFailure(
      failure.runtimeType.toString(),
      'Auth exception mapped',
      cause: error,
      stackTrace: stackTrace,
      context: {'code': error.code, 'message': error.message},
    );
    return failure;
  }

  AuthFailure _mapAuthExceptionInternal(
      firebase.FirebaseAuthException error, StackTrace stackTrace) {
    if ((error.message ?? '').contains('BILLING_NOT_ENABLED')) {
      return const AuthUnexpectedFailure(
        message:
            'La vérification par SMS n\'est pas disponible pour le moment. Veuillez contacter le support.',
      );
    }
    switch (error.code) {
      // User account errors
      case 'user-disabled':
        return const AccountDisabledFailure();
      case 'user-not-found':
      case 'wrong-password':
        return const InvalidCredentialsFailure();
      
      // Email/credential errors
      case 'invalid-email':
        return const AuthUnexpectedFailure(
          message: 'Adresse email invalide. Veuillez vérifier votre email.',
        );
      case 'invalid-credential':
        return const InvalidCredentialsFailure();

      // Phone auth errors
      case 'invalid-phone-number':
        return const AuthUnexpectedFailure(
          message: 'Numéro de téléphone invalide. Vérifiez le format.',
        );
      case 'missing-phone-number':
        return const AuthUnexpectedFailure(
          message: 'Le numéro de téléphone est requis.',
        );
      case 'quota-exceeded':
        return const AuthUnexpectedFailure(
          message:
              'Quota SMS dépassé. Veuillez réessayer plus tard.',
        );
      case 'app-not-authorized':
        return const AuthUnexpectedFailure(
          message:
              'Application non autorisée pour la vérification SMS.',
        );
      case 'captcha-check-failed':
        return const AuthUnexpectedFailure(
          message:
              'Vérification reCAPTCHA échouée. Réessayez.',
        );
      case 'internal-error':
        return const AuthUnexpectedFailure(
          message:
              'Erreur interne lors de la vérification du téléphone.',
        );
      
      // Network errors
      case 'network-request-failed':
      case 'network-error':
        return AuthNetworkFailure(cause: error, stackTrace: stackTrace);
      
      // Rate limiting
      case 'too-many-requests':
        return const AuthUnexpectedFailure(
          message: 'Trop de tentatives. Veuillez réessayer plus tard.',
        );
      
      // Operation errors
      case 'operation-not-allowed':
        return const AuthUnexpectedFailure(
          message: 'Cette opération n\'est pas autorisée.',
        );
      case 'user-cancelled':
        return const UserCancelledFailure();
      
      // Generic fallback
      default:
        return AuthUnexpectedFailure(
          message: 'Une erreur s\'est produite lors de la connexion.',
          cause: error,
          stackTrace: stackTrace,
        );
    }
  }

  AuthFailure _mapSignupException(
      firebase.FirebaseAuthException error, StackTrace stackTrace) {
    final failure = _mapSignupExceptionInternal(error, stackTrace);
    LoggerService.logFailure(
      failure.runtimeType.toString(),
      'Signup exception mapped',
      cause: error,
      stackTrace: stackTrace,
      context: {'code': error.code, 'message': error.message},
    );
    return failure;
  }

  AuthFailure _mapSignupExceptionInternal(
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
