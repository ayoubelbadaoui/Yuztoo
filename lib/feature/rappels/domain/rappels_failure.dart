import '../../../../core/domain/core/failure.dart';

/// Base failure type for rappels / auto-notification operations.
sealed class RappelsFailure extends AppFailure {
  const RappelsFailure(super.message, {super.cause, super.stackTrace});
}

/// Network error during rappels operation.
final class RappelsNetworkFailure extends RappelsFailure {
  const RappelsNetworkFailure({
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          'Network error / Erreur réseau',
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// Unexpected error during rappels operation.
final class RappelsUnexpectedFailure extends RappelsFailure {
  const RappelsUnexpectedFailure({
    String message = 'Unexpected error / Erreur inattendue',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}
