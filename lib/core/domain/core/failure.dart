import 'package:equatable/equatable.dart';

/// Base failure type for the domain layer.
abstract base class AppFailure extends Equatable {
  const AppFailure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => <Object?>[message, cause, stackTrace];
}

/// Represents connectivity or request-level errors.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    String message = 'Network error. Please try again.',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}

/// Represents server-side or unexpected exceptions.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({
    String message = 'Something went wrong.',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}
