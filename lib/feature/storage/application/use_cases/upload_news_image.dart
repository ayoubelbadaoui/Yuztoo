import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/storage_failure.dart';

/// Upload a news/actualite image for a merchant.
class UploadNewsImage {
  const UploadNewsImage(this.storageRepository);

  final StorageRepository storageRepository;

  Future<Result<String>> call({
    required String filePath,
    required String merchantId,
  }) async {
    if (merchantId.isEmpty) {
      return const Left(
        StorageUnexpectedFailure(
          message: 'L\'identifiant du commerce est requis',
        ),
      );
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'merchants/$merchantId/news/$stamp.jpg';

    return storageRepository.uploadImage(
      filePath: filePath,
      storagePath: storagePath,
    );
  }
}
