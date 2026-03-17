import '../../../../core/domain/core/result.dart';

/// Repository interface for storage operations (Firebase Storage).
/// 
/// This interface is in the domain layer and contains no Firebase types.
/// Implementations should be in the infrastructure layer.
abstract class StorageRepository {
  /// Upload an image file to Firebase Storage.
  /// 
  /// [filePath] - Local file path to upload
  /// [storagePath] - Storage path (e.g., 'merchants/{merchantId}/logo.png')
  /// 
  /// Returns Result<String> - Download URL on success, failure on error
  Future<Result<String>> uploadImage({
    required String filePath,
    required String storagePath,
  });

  /// Delete an image from Firebase Storage.
  /// 
  /// [storagePath] - Storage path to delete
  /// 
  /// Returns Result<Unit> on success, failure on error
  Future<Result<Unit>> deleteImage(String storagePath);
}
