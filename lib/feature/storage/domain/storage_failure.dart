import '../../../../core/domain/core/failure.dart';

/// Base failure type for storage operations.
sealed class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause, super.stackTrace});
}

/// Network failure during storage operation
final class StorageNetworkFailure extends StorageFailure {
  const StorageNetworkFailure({
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          'Network error / Erreur réseau',
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// Permission denied failure
final class StoragePermissionDeniedFailure extends StorageFailure {
  const StoragePermissionDeniedFailure({
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          'Permission refusée',
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// File not found failure
final class StorageFileNotFoundFailure extends StorageFailure {
  const StorageFileNotFoundFailure({
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          'File not found / Fichier introuvable',
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// Upload failed
final class StorageUploadFailure extends StorageFailure {
  const StorageUploadFailure({
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          'Upload failed / Échec du téléversement',
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// Unexpected storage failure
final class StorageUnexpectedFailure extends StorageFailure {
  const StorageUnexpectedFailure({
    String message = 'Unexpected error / Erreur inattendue',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}
