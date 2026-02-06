import '../../../../core/domain/core/failure.dart';

/// Base failure type for merchant operations.
sealed class MerchantFailure extends AppFailure {
  const MerchantFailure(super.message, {super.cause, super.stackTrace});
}

/// Merchant already exists in the system.
final class MerchantAlreadyExistsFailure extends MerchantFailure {
  const MerchantAlreadyExistsFailure()
      : super('Merchant already exists / Le commerce existe déjà');
}

/// Unable to create merchant due to system error.
final class UnableToCreateMerchantFailure extends MerchantFailure {
  const UnableToCreateMerchantFailure({
    String message = 'Unable to create merchant / Impossible de créer le profil commerçant',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}

/// Network error during merchant operation.
final class MerchantNetworkFailure extends MerchantFailure {
  const MerchantNetworkFailure({
    String message = 'Erreur réseau lors de l\'opération.',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message,
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// Unexpected error during merchant operation.
final class MerchantUnexpectedFailure extends MerchantFailure {
  const MerchantUnexpectedFailure({
    String message = 'Unexpected merchant error.',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}

