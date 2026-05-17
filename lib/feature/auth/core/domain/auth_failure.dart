import '../../../../../core/domain/core/failure.dart';

sealed class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.cause, super.stackTrace});
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super('Invalid credentials. Please check your email and password.');
}

final class UserCancelledFailure extends AuthFailure {
  const UserCancelledFailure() : super('The operation was cancelled by the user.');
}

final class AccountDisabledFailure extends AuthFailure {
  const AccountDisabledFailure() : super('This account has been disabled.');
}

final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure({Object? cause, StackTrace? stackTrace})
      : super('Network error during authentication.', cause: cause, stackTrace: stackTrace);
}

final class AuthUnexpectedFailure extends AuthFailure {
  // Default message is French — every signup/login error eventually flows
  // through this failure type, and the previous English default leaked
  // straight to the user (the "unexpected error" snackbar that prevented
  // email signup). Callers that have specific French copy should still
  // pass `message: ...` to override.
  const AuthUnexpectedFailure({
    String message =
        'Une erreur est survenue. Vérifiez votre connexion et réessayez.',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}

final class ProfileIncompleteFailure extends AuthFailure {
  const ProfileIncompleteFailure()
      : super('Profile incomplete');
}
