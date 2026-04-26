import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/auth_failure.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/value_objects/email_address.dart';
import '../domain/value_objects/password.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import 'dto/auth_user_dto.dart';

part 'firebase_auth_repository.creds.part.dart';
part 'firebase_auth_repository.phone.part.dart';
part 'firebase_auth_repository.session.part.dart';

abstract class _FirebaseAuthRepositoryBase {
  _FirebaseAuthRepositoryBase(this._auth, this._firestore);

  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static bool _isStatusBlocked(Map<String, dynamic>? data) {
    if (data == null) return false;
    final raw = data['status'];
    if (raw is! String) return false;
    return raw.trim().toLowerCase() == 'blocked';
  }

  /// Builds [AuthUser] from Firestore profile, or blocks access when `status` is `blocked`.
  Future<Result<AuthUser?>> _profileToAuthResult(
    firebase.User user,
    DocumentSnapshot<Map<String, dynamic>>? profileDoc,
  ) async {
    if (profileDoc != null && profileDoc.exists) {
      final data = profileDoc.data();
      if (_isStatusBlocked(data)) {
        try {
          await _auth.signOut();
        } catch (_) {
          // Best-effort — still deny in-app session
        }
        return const Left<AuthFailure, AuthUser?>(AccountDisabledFailure());
      }
    }
    final dto = profileDoc != null && profileDoc.exists
        ? AuthUserDto.fromFirebase(user, profileDoc: profileDoc)
        : AuthUserDto.fromFirebase(user);
    return Right<AuthFailure, AuthUser?>(dto.toDomain());
  }

  AuthFailure _mapAuthException(
      firebase.FirebaseAuthException error, StackTrace stackTrace) {
    switch (error.code) {
      case 'user-disabled':
        return const AccountDisabledFailure();
      case 'email-already-in-use':
        return const AuthUnexpectedFailure(
          message:
              'Vous avez déjà un compte avec cette adresse e-mail — impossible d’en créer un second. Connectez-vous.',
        );
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return const AuthUnexpectedFailure(
          message:
              'Vous avez déjà un compte avec cet email ou ce numéro — un seul compte par identifiant. Connectez-vous.',
        );
      case 'phone-number-already-exists':
        return const AuthUnexpectedFailure(
          message:
              'Vous avez déjà un compte avec ce numéro — nous ne créons pas deux comptes pour le même numéro. Connectez-vous.',
        );
      case 'user-token-expired':
      case 'invalid-user-token':
      case 'requires-recent-login':
        return const AuthUnexpectedFailure(
          message: 'Erreur de session.',
        );
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
      case 'app-not-authorized':
        return const AuthUnexpectedFailure(
          message:
              'L\'application n\'est pas autorisée à utiliser Firebase Auth. Ajoutez l\'empreinte SHA-1 dans la console Firebase.',
        );
      case 'internal-error':
        // Check if it's a billing error
        if (error.message?.contains('BILLING_NOT_ENABLED') == true ||
            error.message?.toLowerCase().contains('billing') == true) {
          return const AuthUnexpectedFailure(
            message:
                'La vérification par SMS n\'est pas disponible pour le moment. Veuillez réessayer plus tard ou contacter le support.',
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
            message:
                'La vérification par SMS n\'est pas disponible pour le moment. Veuillez réessayer plus tard ou contacter le support.',
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
          message:
              'Vous avez déjà un compte avec cette adresse e-mail — impossible d’en créer un second. Connectez-vous.',
        );
      case 'weak-password':
        return const AuthUnexpectedFailure(
            message: 'Le mot de passe est trop faible');
      case 'invalid-email':
        return const AuthUnexpectedFailure(message: 'Adresse e-mail non valide');
      case 'phone-number-already-exists':
        return const AuthUnexpectedFailure(
          message:
              'Vous avez déjà un compte avec ce numéro — nous ne créons pas deux comptes pour le même numéro. Connectez-vous.',
        );
      case 'credential-already-in-use':
        return const AuthUnexpectedFailure(
          message:
              'Vous avez déjà un compte avec cet email ou ce numéro — un seul compte par identifiant. Connectez-vous.',
        );
      case 'account-exists-with-different-credential':
        return const AuthUnexpectedFailure(
          message:
              'Vous avez déjà un compte avec cet email ou ce numéro — un seul compte par identifiant. Connectez-vous.',
        );
      case 'invalid-verification-code':
        return const AuthUnexpectedFailure(
            message: 'Code de vérification invalide');
      case 'user-token-expired':
      case 'invalid-user-token':
      case 'requires-recent-login':
        return const AuthUnexpectedFailure(
          message: 'Erreur de session.',
        );
      case 'network-request-failed':
        return AuthNetworkFailure(cause: error, stackTrace: stackTrace);
      default:
        return AuthUnexpectedFailure(cause: error, stackTrace: stackTrace);
    }
  }
}

class FirebaseAuthRepository extends _FirebaseAuthRepositoryBase
    with
        _FirebaseAuthRepositoryCreds,
        _FirebaseAuthRepositoryPhone,
        _FirebaseAuthRepositorySession
    implements AuthRepository {
  FirebaseAuthRepository({
    required firebase.FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : super(auth, firestore);
}
