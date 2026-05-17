import '../domain/auth_failure.dart';
import '../../../../core/domain/core/failure.dart';

/// Maps [AuthFailure] / [AppFailure] to French messages for snackbars and dialogs.
class AuthErrorMapper {
  /// Legacy mapper — prefer [displayMessage] for UI (never returns null).
  static String? getFrenchMessage(AppFailure failure) {
    final message = displayMessage(failure);
    if (_isGenericFallback(message)) return null;
    return message;
  }

  /// User-facing message; always non-empty.
  static String displayMessage(AppFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return 'Identifiants incorrects. Vérifiez votre adresse e-mail et votre mot de passe.';
    }
    if (failure is AccountDisabledFailure) {
      return 'Compte désactivé.';
    }
    if (failure is AuthNetworkFailure) {
      return 'Erreur réseau. Vérifiez votre connexion à Internet.';
    }
    if (failure is UserCancelledFailure) {
      return 'Opération annulée.';
    }
    if (failure is ProfileIncompleteFailure) {
      return 'Profil incomplet';
    }

    final trimmed = failure.message.trim();
    if (trimmed.isNotEmpty && !_isGenericDefault(trimmed)) {
      return trimmed;
    }

    if (failure is AuthUnexpectedFailure && failure.cause != null) {
      return 'Une erreur s\'est produite. Veuillez réessayer.';
    }

    if (trimmed.isNotEmpty) return trimmed;

    return 'Une erreur s\'est produite. Veuillez réessayer.';
  }

  static bool _isGenericDefault(String message) {
    final lower = message.toLowerCase();
    return lower.contains('une erreur est survenue') ||
        lower.contains('une erreur s\'est produite') ||
        lower.contains('something went wrong') ||
        lower.contains('network error during authentication') ||
        lower.contains('an unexpected error');
  }

  static bool _isGenericFallback(String message) =>
      message == 'Une erreur s\'est produite. Veuillez réessayer.';
}
