import '../../core/domain/core/failure.dart';
import '../../feature/auth/domain/auth_failure.dart';

/// Maps AppFailure (specifically AuthFailure) to French error messages for UI display
String mapAuthFailureToFrench(AppFailure failure) {
  if (failure is AuthFailure) {
    return switch (failure) {
      InvalidCredentialsFailure(:final message) => message.isNotEmpty 
          ? message 
          : 'Identifiants invalides. Vérifiez votre email et mot de passe.',
      EmailAlreadyInUseFailure() => 'Cette adresse email est déjà utilisée',
      WeakPasswordFailure() => 'Le mot de passe est trop faible',
      InvalidEmailFailure() => 'Adresse email invalide',
      PhoneAlreadyExistsFailure() => 'Ce numéro de téléphone est déjà utilisé',
      InvalidVerificationCodeFailure() => 'Code de vérification invalide',
      UserCancelledFailure() => 'Opération annulée par l\'utilisateur.',
      AccountDisabledFailure() => 'Ce compte a été désactivé.',
      AuthNetworkFailure() => 'Erreur de connexion réseau. Vérifiez votre connexion internet.',
      AuthUnexpectedFailure(:final message) => message.isNotEmpty 
          ? message 
          : 'Une erreur s\'est produite. Veuillez réessayer.',
    };
  }
  return failure.message;
}

