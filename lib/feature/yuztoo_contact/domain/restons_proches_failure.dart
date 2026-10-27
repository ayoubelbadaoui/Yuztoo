import '../../../core/domain/core/failure.dart';

sealed class RestonsProchesFailure extends AppFailure {
  const RestonsProchesFailure(super.message);
}

final class RestonsProchesNotConfiguredFailure extends RestonsProchesFailure {
  const RestonsProchesNotConfiguredFailure()
      : super('Page Restons proches non configurée pour ce projet.');
}

final class RestonsProchesPermissionFailure extends RestonsProchesFailure {
  const RestonsProchesPermissionFailure()
      : super('Vous n\'êtes pas autorisé à modifier cette page.');
}

final class RestonsProchesUnexpectedFailure extends RestonsProchesFailure {
  const RestonsProchesUnexpectedFailure(super.message);
}
