import '../../../../core/domain/core/failure.dart';

/// Base failure type for client notification operations.
sealed class ClientNotificationFailure extends AppFailure {
  const ClientNotificationFailure(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// Network error during a notification operation.
final class ClientNotificationNetworkFailure
    extends ClientNotificationFailure {
  const ClientNotificationNetworkFailure({
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          'Erreur réseau lors de la notification.',
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// Unexpected error during a notification operation.
final class ClientNotificationUnexpectedFailure
    extends ClientNotificationFailure {
  const ClientNotificationUnexpectedFailure({
    String message = 'Une erreur inattendue est survenue.',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}
