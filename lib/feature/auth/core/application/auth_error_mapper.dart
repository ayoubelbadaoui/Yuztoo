import '../domain/auth_failure.dart';
import '../../../../core/domain/core/failure.dart';

/// Maps AuthFailure and AppFailure to French error messages for UI display
class AuthErrorMapper {
  /// Get French error message from AuthFailure or AppFailure
  /// Returns null if error is too generic (not from Firebase)
  static String? getFrenchMessage(AppFailure failure) {
    if (failure is AuthFailure) {
      return _getAuthFailureMessage(failure);
    }
    // Handle generic AppFailure - only show if it has a specific message
    if (failure.message.isNotEmpty && 
        !failure.message.toLowerCase().contains('une erreur s\'est produite')) {
      return failure.message;
    }
    // Don't show generic errors - return null to indicate no error should be shown
    return null;
  }

  static String? _getAuthFailureMessage(AuthFailure failure) {
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
      // Use the message from the failure if it's already in French and specific
      final message = failure.message;
      // Only return message if it's specific (not generic)
      if (message.isNotEmpty && 
          (message.contains('email') || 
           message.contains('mot de passe') ||
           message.contains('téléphone') ||
           message.contains('vérification') ||
           message.contains('facturation') ||
           message.contains('billing') ||
           message.contains('quota') ||
           message.contains('SMS'))) {
        return message;
      }
      // Check if it's a real Firebase error (has cause/stackTrace)
      if (failure.cause != null) {
        // This is a real Firebase error - show generic message
        return 'Une erreur s\'est produite. Veuillez réessayer.';
      }
      // Not a real Firebase error - don't show generic message
      return null;
    }
    // Unknown failure type - only show if it's a real Firebase error
    return null;
  }
}

