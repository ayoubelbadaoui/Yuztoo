import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../domain/repositories/storage_repository.dart';
import '../domain/storage_failure.dart';

/// Firebase Storage implementation of StorageRepository.
class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository({
    required FirebaseStorage storage,
  }) : _storage = storage;

  final FirebaseStorage _storage;

  @override
  Future<Result<String>> uploadImage({
    required String filePath,
    required String storagePath,
  }) async {
    if (filePath.isEmpty || storagePath.isEmpty) {
      return const Left<StorageFailure, String>(
        StorageUnexpectedFailure(
          message: 'File path and storage path are required',
        ),
      );
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return const Left<StorageFailure, String>(
        StorageFileNotFoundFailure(),
      );
    }

    try {
      final ref = _storage.ref(storagePath);
      
      // Upload file
      final uploadTask = ref.putFile(file);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      LoggerService.logInfo(
        'Image uploaded successfully',
        context: {
          'storagePath': storagePath,
          'downloadUrl': downloadUrl,
        },
      );
      
      return Right<StorageFailure, String>(downloadUrl);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase Storage error uploading image',
        error: e,
        stackTrace: st,
        context: {
          'storagePath': storagePath,
          'filePath': filePath,
          'code': e.code,
        },
      );

      if (e.code == 'permission-denied') {
        return const Left<StorageFailure, String>(
          StoragePermissionDeniedFailure(),
        );
      }

      return Left<StorageFailure, String>(
        StorageUploadFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error uploading image',
        error: e,
        stackTrace: st,
        context: {
          'storagePath': storagePath,
          'filePath': filePath,
        },
      );
      return Left<StorageFailure, String>(
        StorageUnexpectedFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> deleteImage(String storagePath) async {
    if (storagePath.isEmpty) {
      return const Left<StorageFailure, Unit>(
        StorageUnexpectedFailure(
          message: 'Storage path is required',
        ),
      );
    }

    try {
      final ref = _storage.ref(storagePath);
      await ref.delete();
      
      LoggerService.logInfo(
        'Image deleted successfully',
        context: {'storagePath': storagePath},
      );
      
      return const Right<StorageFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase Storage error deleting image',
        error: e,
        stackTrace: st,
        context: {
          'storagePath': storagePath,
          'code': e.code,
        },
      );

      if (e.code == 'permission-denied') {
        return const Left<StorageFailure, Unit>(
          StoragePermissionDeniedFailure(),
        );
      }

      if (e.code == 'object-not-found') {
        return const Left<StorageFailure, Unit>(
          StorageFileNotFoundFailure(),
        );
      }

      return Left<StorageFailure, Unit>(
        StorageUnexpectedFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error deleting image',
        error: e,
        stackTrace: st,
        context: {'storagePath': storagePath},
      );
      return Left<StorageFailure, Unit>(
        StorageUnexpectedFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
