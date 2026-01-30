import '../domain/auth_failure.dart';
import '../../../../core/domain/core/failure.dart';

/// Maps AuthFailure and AppFailure to French error messages for UI display
class AuthErrorMapper {
  /// Get French error message from AuthFailure or AppFailure
  static String getFrenchMessage(AppFailure failure) {
    if (failure is AuthFailure) {
      return _getAuthFailureMessage(failure);
    }
    // Handle generic AppFailure
    return failure.message.isNotEmpty 
        ? failure.message 
        : 'Une erreur s\'est produite. Veuillez réessayer.';
  }

  static String _getAuthFailureMessage(AuthFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return 'Identifiants invalides. Vérifiez votre email et mot de passe.';
    }
    if (failure is AccountDisabledFailure) {
      return 'Ce compte a été désactivé.';
    }
    if (failure is AuthNetworkFailure) {
      return 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
    }
    if (failure is UserCancelledFailure) {
      return 'Opération annulée par l\'utilisateur.';
    }
    if (failure is AuthUnexpectedFailure) {
      // Use the message from the failure if it's already in French
      // Otherwise return generic message
      final message = failure.message;
      if (message.contains('email') || 
          message.contains('mot de passe') ||
          message.contains('téléphone') ||
          message.contains('vérification') ||
          message.contains('Profil utilisateur') ||
          message.contains('profil') ||
          message.contains('introuvable')) {
        return message;
      }
      return 'Une erreur s\'est produite. Veuillez réessayer.';
    }
    return 'Une erreur s\'est produite. Veuillez réessayer.';
  }
}

