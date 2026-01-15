import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/entities/auth_user.dart';
import '../../domain/auth/repositories/auth_repository.dart';
import '../../domain/auth/value_objects/email_address.dart';
import '../../domain/auth/value_objects/password.dart';
import '../../domain/core/either.dart';
import '../../domain/core/result.dart';
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
      default:
        return AuthUnexpectedFailure(cause: error, stackTrace: stackTrace);
    }
  }
}
