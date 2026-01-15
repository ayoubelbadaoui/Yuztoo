import '../core/failure.dart';

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
  const AuthUnexpectedFailure({
    String message = 'Unexpected authentication error.',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}
