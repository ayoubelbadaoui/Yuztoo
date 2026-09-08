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

/// Shown whenever SMS verification is refused for a reason the user cannot act
/// on — app attestation (Android Play Integrity / iOS silent push), provider
/// configuration, or an unrecognised backend error. The technical cause goes to
/// Crashlytics via [LoggerService]; the user gets a way forward instead.
const String _smsUnavailableMessage =
    'L\'envoi du code SMS est momentanément indisponible. '
    'Réessayez dans quelques minutes ou contactez le support si le problème persiste.';

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
    DocumentSnapshot<Map<String, dynamic>>? profileDoc, {
    String? oauthFirstName,
    String? oauthLastName,
  }) async {
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
        ? AuthUserDto.fromFirebase(
            user,
            profileDoc: profileDoc,
            oauthFirstName: oauthFirstName,
            oauthLastName: oauthLastName,
          )
        : AuthUserDto.fromFirebase(
            user,
            oauthFirstName: oauthFirstName,
            oauthLastName: oauthLastName,
          );
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
      case 'invalid-phone-number':
        return const AuthUnexpectedFailure(
          message:
              'Numéro de téléphone invalide. Utilisez le format international (ex. +33 6 12 34 56 78).',
        );
      case 'too-many-requests':
        return const AuthUnexpectedFailure(
          message:
              'Trop de tentatives. Attendez quelques minutes avant de redemander un code SMS.',
        );
      case 'quota-exceeded':
        return const AuthUnexpectedFailure(
          message:
              'Quota SMS dépassé. Réessayez plus tard ou contactez le support.',
        );
      case 'operation-not-allowed':
        return const AuthUnexpectedFailure(
          message:
              'La vérification par SMS n\'est pas activée pour cette application. Contactez le support.',
        );
      case 'missing-client-identifier':
        return const AuthUnexpectedFailure(
          message: _smsUnavailableMessage,
        );
      case 'captcha-check-failed':
        return const AuthUnexpectedFailure(
          message:
              'Vérification anti-spam échouée. Réessayez ou utilisez un autre réseau.',
        );
      case 'user-cancelled':
        return const UserCancelledFailure();
      case 'app-not-authorized':
        return const AuthUnexpectedFailure(
          message: _smsUnavailableMessage,
        );
      case 'internal-error':
        return _mapPhoneOrInternalAuthFailure(error, stackTrace);
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
        // Unmapped code: report it so it shows up as a Crashlytics non-fatal
        // and can be given proper copy later. The user gets none of this.
        LoggerService.logError(
          'Unmapped FirebaseAuthException',
          error: error,
          stackTrace: stackTrace,
          context: {'code': error.code},
        );
        return AuthUnexpectedFailure(
          message: 'Connexion impossible pour le moment. '
              'Réessayez ou contactez le support.',
          cause: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// Maps Firebase phone-SMS failures to actionable French copy (signup OTP).
  AuthFailure _mapPhoneVerificationException(
    firebase.FirebaseAuthException error,
    StackTrace stackTrace,
  ) {
    final errorMessage = error.message ?? '';
    final lower = errorMessage.toLowerCase();

    if (errorMessage.contains('BILLING_NOT_ENABLED') ||
        lower.contains('billing')) {
      return const AuthUnexpectedFailure(
        message:
            'La vérification par SMS n\'est pas disponible pour le moment. Veuillez réessayer plus tard ou contacter le support.',
      );
    }

    if (error.code == 'app-not-authorized' ||
        errorMessage.contains('INVALID_CERT_HASH') ||
        lower.contains('missing client identifier') ||
        lower.contains('package certificate hash') ||
        lower.contains('certificate hash')) {
      return const AuthUnexpectedFailure(
        message: _smsUnavailableMessage,
      );
    }

    if (lower.contains('recaptcha') || lower.contains('play_integrity')) {
      return const AuthUnexpectedFailure(
        message:
            'Impossible d\'envoyer le SMS (vérification de l\'appareil échouée). Mettez à jour l\'app, vérifiez Google Play Services, puis réessayez.',
      );
    }

    return _mapAuthException(error, stackTrace);
  }

  AuthFailure _mapPhoneOrInternalAuthFailure(
    firebase.FirebaseAuthException error,
    StackTrace stackTrace,
  ) {
    final errorMessage = error.message ?? '';
    final lower = errorMessage.toLowerCase();

    if (errorMessage.contains('BILLING_NOT_ENABLED') ||
        lower.contains('billing')) {
      return const AuthUnexpectedFailure(
        message:
            'La vérification par SMS n\'est pas disponible pour le moment. Veuillez réessayer plus tard ou contacter le support.',
      );
    }

    if (lower.contains('certificate') ||
        lower.contains('cert_hash') ||
        lower.contains('invalid_cert')) {
      return const AuthUnexpectedFailure(
        message: _smsUnavailableMessage,
      );
    }

    if (lower.contains('recaptcha') || lower.contains('play_integrity')) {
      return const AuthUnexpectedFailure(
        message:
            'Impossible d\'envoyer le SMS (vérification de l\'appareil échouée). Réessayez sur un autre réseau.',
      );
    }

    return AuthUnexpectedFailure(
      message: _smsUnavailableMessage,
      cause: error,
      stackTrace: stackTrace,
    );
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
        // Same rationale as _mapAuthException: report the code rather than
        // showing it, so an unhandled signup failure stays debuggable.
        LoggerService.logError(
          'Unmapped signup FirebaseAuthException',
          error: error,
          stackTrace: stackTrace,
          context: {'code': error.code},
        );
        return AuthUnexpectedFailure(
          message: 'Inscription impossible pour le moment. '
              'Réessayez ou contactez le support.',
          cause: error,
          stackTrace: stackTrace,
        );
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
