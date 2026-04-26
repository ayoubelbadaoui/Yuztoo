import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/storage_failure.dart';

/// Use case for uploading merchant logo to Firebase Storage.
/// 
/// This use case:
/// - Uploads logo image to Storage at merchants/{merchantId}/logo.png
/// - Returns download URL on success
class UploadLogo {
  const UploadLogo(this.storageRepository);

  final StorageRepository storageRepository;

  /// Upload logo for a merchant.
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
          message: 'L\'identifiant du commerce est requis',
        ),
      );
    }

    // Storage path: merchants/{merchantId}/logo.png
    final storagePath = 'merchants/$merchantId/logo.png';

    return await storageRepository.uploadImage(
      filePath: filePath,
      storagePath: storagePath,
    );
  }
}

