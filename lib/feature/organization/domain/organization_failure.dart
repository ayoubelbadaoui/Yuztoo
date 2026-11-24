import '../../../core/domain/core/failure.dart';

/// Base failure type for enseigne operations.
sealed class OrganizationFailure extends AppFailure {
  const OrganizationFailure(super.message, {super.cause, super.stackTrace});
}

final class OrganizationNetworkFailure extends OrganizationFailure {
  const OrganizationNetworkFailure({super.cause, super.stackTrace})
      : super('Connexion impossible. Réessayez.');
}

final class OrganizationNotFoundFailure extends OrganizationFailure {
  const OrganizationNotFoundFailure() : super('Enseigne introuvable.');
}

final class OrganizationValidationFailure extends OrganizationFailure {
  const OrganizationValidationFailure(super.message);
}
