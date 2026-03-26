import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/storage/application/use_cases/upload_logo.dart';
import 'package:flutter_yuztoo/feature/storage/domain/repositories/storage_repository.dart';
import 'package:flutter_yuztoo/feature/storage/domain/storage_failure.dart';

/// Fake storage repository that records upload calls and returns configurable result.
class _FakeStorageRepository implements StorageRepository {
  String? lastFilePath;
  String? lastStoragePath;
  Result<String> uploadResult =
      const Right('https://storage.example.com/merchants/m1/logo.png');

  @override
  Future<Result<String>> uploadImage({
    required String filePath,
    required String storagePath,
  }) async {
    lastFilePath = filePath;
    lastStoragePath = storagePath;
    return uploadResult;
  }

  @override
  Future<Result<Unit>> deleteImage(String storagePath) async {
    return const Right(unit);
  }
}

void main() {
  group('UploadLogo', () {
    late _FakeStorageRepository fakeRepo;
    late UploadLogo useCase;

    setUp(() {
      fakeRepo = _FakeStorageRepository();
      useCase = UploadLogo(fakeRepo);
    });

    test('calls repository with path merchants/{merchantId}/logo.png', () async {
      fakeRepo.uploadResult = const Right('https://storage.example.com/logo.png');

      final result = await useCase.call(
        filePath: '/tmp/test_logo.png',
        merchantId: 'merchant-abc',
      );

      expect(result.isRight, true);
      expect(fakeRepo.lastFilePath, '/tmp/test_logo.png');
      expect(fakeRepo.lastStoragePath, 'merchants/merchant-abc/logo.png');
      result.fold(
        (_) => fail('Expected success'),
        (url) => expect(url, 'https://storage.example.com/logo.png'),
      );
    });

    test('returns download URL on success', () async {
      const url = 'https://firebasestorage.googleapis.com/v0/b/bucket/o/merchants%2Fm1%2Flogo.png?alt=media';
      fakeRepo.uploadResult = const Right(url);

      final result = await useCase.call(
        filePath: '/path/to/logo.png',
        merchantId: 'm1',
      );

      expect(result.isRight, true);
      result.fold(
        (_) => fail('Expected success'),
        (downloadUrl) => expect(downloadUrl, url),
      );
    });

    test('returns failure when merchantId is empty', () async {
      final result = await useCase.call(
        filePath: '/tmp/logo.png',
        merchantId: '',
      );

      expect(result.isLeft, true);
      expect(fakeRepo.lastStoragePath, isNull);
    });

    test('returns failure when repository fails', () async {
      fakeRepo.uploadResult = const Left(StoragePermissionDeniedFailure());

      final result = await useCase.call(
        filePath: '/tmp/logo.png',
        merchantId: 'm1',
      );

      expect(result.isLeft, true);
    });
  });
}
