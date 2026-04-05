import '../../domain/repositories/storage_repository.dart';
import '../../../../core/domain/core/result.dart';

class DeleteStorageImage {
  const DeleteStorageImage(this._repository);

  final StorageRepository _repository;

  Future<Result<Unit>> call(String storagePath) =>
      _repository.deleteImage(storagePath);
}
