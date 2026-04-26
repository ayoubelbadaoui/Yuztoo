import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/storage_failure.dart';

/// Uploads a client profile photo to `users/{uid}/avatar.jpg`.
class UploadClientAvatar {
  const UploadClientAvatar(this.storageRepository);

  final StorageRepository storageRepository;

  Future<Result<String>> call({
    required String filePath,
    required String uid,
  }) async {
    if (uid.isEmpty) {
      return const Left(
        StorageUnexpectedFailure(
          message: 'L\'identifiant utilisateur est requis',
        ),
      );
    }

    final storagePath = 'users/$uid/avatar.jpg';

    return storageRepository.uploadImage(
      filePath: filePath,
      storagePath: storagePath,
    );
  }
}
