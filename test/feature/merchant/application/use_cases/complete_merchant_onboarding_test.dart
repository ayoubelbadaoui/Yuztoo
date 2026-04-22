import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/merchant/application/use_cases/complete_merchant_onboarding.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/merchant_failure.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/repositories/merchant_repository.dart';

class _FakeMerchantRepository implements MerchantRepository {
  bool _shouldFailCreate = false;
  Merchant? _createdMerchant;
  String? _linkedUserId;

  void setShouldFailCreate(bool fail) {
    _shouldFailCreate = fail;
  }

  Merchant? getCreatedMerchant() => _createdMerchant;
  String? getLinkedUserId() => _linkedUserId;

  @override
  Future<Result<bool>> merchantExists(String ownerUid) async {
    return const Right<MerchantFailure, bool>(false);
  }

  @override
  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  }) async {
    if (_shouldFailCreate) {
      return const Left<MerchantFailure, Merchant>(
        UnableToCreateMerchantFailure(),
      );
    }
    // MVP: merchantId == userId
    _createdMerchant = merchant.copyWith(id: userId);
    _linkedUserId = userId;
    return Right<MerchantFailure, Merchant>(_createdMerchant!);
  }

  @override
  Future<Result<Merchant?>> getMerchantByOwnerUid(String ownerUid) async {
    if (_createdMerchant != null && _createdMerchant!.ownerUid == ownerUid) {
      return Right<MerchantFailure, Merchant?>(_createdMerchant);
    }
    return const Right<MerchantFailure, Merchant?>(null);
  }

  @override
  Future<Result<Merchant?>> getMerchantById(String merchantId) async {
    if (_createdMerchant != null && _createdMerchant!.id == merchantId) {
      return Right<MerchantFailure, Merchant?>(_createdMerchant);
    }
    return const Right<MerchantFailure, Merchant?>(null);
  }

  @override
  Future<Result<List<Merchant>>> listMerchants({
    int limit = 20,
    String? cityFilter,
    int cityFetchCap = 500,
  }) async {
    if (_createdMerchant == null) {
      return const Right<MerchantFailure, List<Merchant>>(<Merchant>[]);
    }
    return Right<MerchantFailure, List<Merchant>>(<Merchant>[_createdMerchant!]);
  }

  @override
  Future<Result<List<Merchant>>> getMerchantsByIds(List<String> ids) async {
    if (_createdMerchant == null || !ids.contains(_createdMerchant!.id)) {
      return const Right<MerchantFailure, List<Merchant>>(<Merchant>[]);
    }
    return Right<MerchantFailure, List<Merchant>>(<Merchant>[_createdMerchant!]);
  }

  @override
  Future<Result<Unit>> linkExistingMerchantToUser({
    required String merchantId,
    required String userId,
  }) async {
    return const Right<MerchantFailure, Unit>(unit);
  }

  @override
  Future<Result<Merchant>> updateMerchant({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoUrl,
    String? phone,
    String? address,
    String? city,
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
    LoyaltyProgramConfig? loyaltyProgram,
    bool? messagingEnabled,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabledStandalone,
    bool clearCityField = false,
  }) async {
    final current = _createdMerchant;
    if (current == null || current.id != merchantId) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: 'Merchant not found'),
      );
    }
    _createdMerchant = current.copyWith(
      displayName: displayName,
      description: description,
      categories: categories,
      logoUrl: logoUrl,
      phone: phone,
      address: address,
      websiteUrl: websiteUrl,
      bannerUrl: bannerUrl,
      newsImageUrls: newsImageUrls,
      status: status,
      hours: hours,
      rappelsAutoClientValidation: rappelsAutoClientValidation,
      rappelsAutoPassageValidation: rappelsAutoPassageValidation,
      loyaltyProgram: loyaltyProgram,
      loyaltyEnabled: loyaltyProgram?.programEnabled ?? current.loyaltyEnabled,
    );
    return Right<MerchantFailure, Merchant>(_createdMerchant!);
  }
}

void main() {
  group('CompleteMerchantOnboarding', () {
    late _FakeMerchantRepository repository;
    late CompleteMerchantOnboarding useCase;

    setUp(() {
      repository = _FakeMerchantRepository();
      useCase = CompleteMerchantOnboarding(repository);
    });

    test('should create merchant successfully with all required fields', () async {
      final result = await useCase.call(
        userId: 'user-123',
        name: 'Test Business',
        email: 'test@business.com',
        phone: '+33123456789',
        city: 'Paris',
      );

      expect(result.isRight, true);
      result.fold(
        (failure) => fail('Should not fail: $failure'),
        (merchant) {
          // MVP: merchantId == userId
          expect(merchant.id, 'user-123');
          expect(merchant.ownerUid, 'user-123');
          expect(merchant.name, 'Test Business');
          expect(merchant.email, 'test@business.com');
          expect(merchant.phone, '+33123456789');
          expect(merchant.city, 'Paris');
          expect(merchant.status, 'active');
          expect(repository.getLinkedUserId(), 'user-123');
        },
      );
    });

    test('should create merchant with optional fields', () async {
      final result = await useCase.call(
        userId: 'user-456',
        name: 'Another Business',
        email: 'another@business.com',
        phone: '+33987654321',
        city: 'Lyon',
        address: '123 Main St',
        categories: ['Restaurant', 'Café'],
        description: 'A great place to eat',
      );

      expect(result.isRight, true);
      result.fold(
        (failure) => fail('Should not fail: $failure'),
        (merchant) {
          expect(merchant.address, '123 Main St');
          expect(merchant.categories, ['Restaurant', 'Café']);
          expect(merchant.description, 'A great place to eat');
        },
      );
    });

    test('should return error when repository fails', () async {
      repository.setShouldFailCreate(true);

      final result = await useCase.call(
        userId: 'user-789',
        name: 'Failed Business',
        email: 'failed@business.com',
        phone: '+33555666777',
        city: 'Marseille',
      );

      expect(result.isLeft, true);
      result.fold(
        (failure) {
          expect(failure, isA<UnableToCreateMerchantFailure>());
        },
        (_) => fail('Should have failed'),
      );
    });

    test('should create merchant with minimal required fields only', () async {
      final result = await useCase.call(
        userId: 'user-minimal',
        name: 'Minimal Business',
        email: 'minimal@business.com',
        phone: '+33111111111',
        city: 'Toulouse',
      );

      expect(result.isRight, true);
      result.fold(
        (failure) => fail('Should not fail: $failure'),
        (merchant) {
          expect(merchant.address, isNull);
          expect(merchant.categories, isNull);
          expect(merchant.description, isNull);
          expect(merchant.hours, isNull);
        },
      );
    });
  });
}

