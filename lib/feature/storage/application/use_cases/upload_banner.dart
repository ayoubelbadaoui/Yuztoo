import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/storage_failure.dart';

/// Use case for uploading merchant banner to Firebase Storage.
///
/// Uploads banner image to Storage at merchants/{merchantId}/banner.png
/// and returns the download URL on success.
class UploadBanner {
  const UploadBanner(this.storageRepository);

  final StorageRepository storageRepository;

  /// Upload banner for a merchant.
  ///
  /// [filePath] - Local file path to upload
  /// [merchantId] - Merchant ID (used to construct storage path)
  ///
  /// Returns Result<String> - Download URL on success, failure on error
  Future<Result<String>> call({
    required String filePath,
    required String merchantId,
  }) async {
    if (merchantId.isEmpty) {
      return const Left(
        StorageUnexpectedFailure(
          message: 'Merchant ID is required',
        ),
      );
    }

    final storagePath = 'merchants/$merchantId/banner.png';

    return await storageRepository.uploadImage(
      filePath: filePath,
      storagePath: storagePath,
    );
  }
}
