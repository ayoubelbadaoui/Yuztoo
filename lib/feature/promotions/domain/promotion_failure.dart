import '../../../../core/domain/core/failure.dart';

/// Base failure type for promotion operations.
sealed class PromotionFailure extends AppFailure {
  const PromotionFailure(super.message, {super.cause, super.stackTrace});
}

/// Network error during promotion operation.
final class PromotionNetworkFailure extends PromotionFailure {
  const PromotionNetworkFailure({
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          'Network error / Erreur réseau',
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// Unexpected error during promotion operation.
final class PromotionUnexpectedFailure extends PromotionFailure {
  const PromotionUnexpectedFailure({
    String message = 'Unexpected error / Erreur inattendue',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}
