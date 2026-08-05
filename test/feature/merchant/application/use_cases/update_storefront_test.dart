import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/merchant/application/use_cases/update_storefront.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant_storefront_link.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/merchant_failure.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/client_gratification_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/repositories/merchant_repository.dart';
import 'package:flutter_yuztoo/feature/storage/application/use_cases/upload_banner.dart';
import 'package:flutter_yuztoo/feature/storage/application/use_cases/upload_logo.dart';
import 'package:flutter_yuztoo/feature/storage/domain/repositories/storage_repository.dart';

/// Fake storage repo: upload returns fixed URLs for logo and banner.
class _FakeStorageRepository implements StorageRepository {
  @override
  Future<Result<String>> uploadImage({
    required String filePath,
    required String storagePath,
  }) async {
    if (storagePath.contains('banner')) {
      return const Right('https://storage.example.com/merchants/m1/banner.png');
    }
    return const Right('https://storage.example.com/merchants/m1/logo.png');
  }

  @override
  Future<Result<Unit>> deleteImage(String storagePath) async {
    return const Right(unit);
  }
}

/// Fake merchant repo: records updateMerchant calls so we can assert logo_url was passed.
class _FakeMerchantRepositoryForUpdate implements MerchantRepository {
  String? lastLogoUrl;
  String? lastMerchantId;
  bool shouldFailUpdate = false;

  @override
  Future<Result<bool>> merchantExists(String ownerUid) async =>
      const Right(false);

  @override
  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  }) async =>
      const Left(MerchantUnexpectedFailure(message: 'not used'));

  @override
  Future<Result<Merchant?>> getMerchantByOwnerUid(String ownerUid) async =>
      const Right(null);

  @override
  Future<Result<Merchant?>> getMerchantById(String merchantId) async => const Right(null);

  @override
  Future<Result<List<Merchant>>> listMerchants({
    int limit = 20,
    String? cityFilter,
    List<String>? cityFilters,
    int cityFetchCap = 500,
  }) async =>
      const Right([]);

  @override
  Future<Result<List<Merchant>>> getMerchantsByIds(List<String> ids) async => const Right([]);

  @override
  Future<Result<Unit>> linkExistingMerchantToUser({
    required String merchantId,
    required String userId,
  }) async =>
      const Right(unit);

  @override
  Future<Result<Merchant>> updateMerchant({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoUrl,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    String? welcomeGiftDescription,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
    bool? passageCooldownEnabled,
    LoyaltyProgramConfig? loyaltyProgram,
    bool? messagingEnabled,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabledStandalone,
    String? merchantType,
    String? categoryId,
    String? subcategoryTitle,
    bool clearCityField = false,
    List<MerchantStorefrontLink>? storefrontLinks,
  }) async {
    lastMerchantId = merchantId;
    lastLogoUrl = logoUrl;
    if (shouldFailUpdate) {
      return const Left(MerchantUnexpectedFailure(message: 'Firestore error'));
    }
    final updated = Merchant(
      id: merchantId,
      ownerUid: merchantId,
      name: displayName ?? 'Store',
      email: 'test@test.com',
      phone: phone ?? '+33123456789',
      city: 'Paris',
      address: address,
      displayName: displayName,
      description: description,
      categories: categories,
      logoUrl: logoUrl,
      websiteUrl: websiteUrl,
      bannerUrl: bannerUrl,
      hours: hours,
    );
    return Right(updated);
  }

  @override
  Future<Result<void>> updateGratificationConfig({
    required String merchantId,
    required ClientGratificationConfig config,
  }) async =>
      const Right<MerchantFailure, void>(null);
}

void main() {
  group('UpdateStorefront', () {
    late _FakeMerchantRepositoryForUpdate merchantRepo;
    late UploadLogo uploadLogoUseCase;
    late UploadBanner uploadBannerUseCase;
    late UpdateStorefront updateStorefrontUseCase;

    setUp(() {
      final fakeStorage = _FakeStorageRepository();
      merchantRepo = _FakeMerchantRepositoryForUpdate();
      uploadLogoUseCase = UploadLogo(fakeStorage);
      uploadBannerUseCase = UploadBanner(fakeStorage);
      updateStorefrontUseCase = UpdateStorefront(
        merchantRepository: merchantRepo,
        uploadLogo: uploadLogoUseCase,
        uploadBanner: uploadBannerUseCase,
      );
    });

    test('uploads logo then saves logoUrl to Firestore', () async {
      final result = await updateStorefrontUseCase.call(
        merchantId: 'm1',
        logoFilePath: '/tmp/logo.png',
      );

      expect(result.isRight, true);
      expect(merchantRepo.lastMerchantId, 'm1');
      expect(merchantRepo.lastLogoUrl, 'https://storage.example.com/merchants/m1/logo.png');
      result.fold(
        (_) => fail('Expected success'),
        (merchant) {
          expect(merchant.logoUrl, 'https://storage.example.com/merchants/m1/logo.png');
        },
      );
    });

    test('updates Firestore without logo when logoFilePath is null', () async {
      final result = await updateStorefrontUseCase.call(
        merchantId: 'm1',
        displayName: 'My Store',
        description: 'A nice store',
      );

      expect(result.isRight, true);
      expect(merchantRepo.lastLogoUrl, isNull);
      expect(merchantRepo.lastMerchantId, 'm1');
    });

    test('returns failure when merchantId is empty', () async {
      final result = await updateStorefrontUseCase.call(
        merchantId: '',
        logoFilePath: '/tmp/logo.png',
      );

      expect(result.isLeft, true);
      expect(merchantRepo.lastMerchantId, isNull);
    });

    test('returns Firestore failure when updateMerchant fails', () async {
      merchantRepo.shouldFailUpdate = true;

      final result = await updateStorefrontUseCase.call(
        merchantId: 'm1',
        logoFilePath: '/tmp/logo.png',
      );

      expect(result.isLeft, true);
      expect(merchantRepo.lastLogoUrl, isNotNull); // upload succeeded, Firestore failed
    });
  });
}
