import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/merchant/application/use_cases/create_merchant_use_case.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/merchant_failure.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/repositories/merchant_repository.dart';

class _FakeMerchantRepository implements MerchantRepository {
  bool _merchantExists = false;
  bool _shouldFailCreate = false;
  Merchant? _createdMerchant;

  void setMerchantExists(bool exists) {
    _merchantExists = exists;
  }

  void setShouldFailCreate(bool fail) {
    _shouldFailCreate = fail;
  }

  Merchant? getCreatedMerchant() => _createdMerchant;

  @override
  Future<Result<bool>> merchantExists(String ownerUid) async {
    if (_shouldFailCreate) {
      return const Left<MerchantFailure, bool>(
        MerchantNetworkFailure(),
      );
    }
    return Right<MerchantFailure, bool>(_merchantExists);
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
    _createdMerchant = merchant.copyWith(id: 'merchant-${DateTime.now().millisecondsSinceEpoch}');
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
  Future<Result<List<Merchant>>> listMerchants({int limit = 20}) async {
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
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
  }) async {
    if (_createdMerchant == null || _createdMerchant!.id != merchantId) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: 'Merchant not found'),
      );
    }
    _createdMerchant = _createdMerchant!.copyWith(
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
    );
    return Right<MerchantFailure, Merchant>(_createdMerchant!);
  }
}

void main() {
  group('CreateMerchantUseCase', () {
    late _FakeMerchantRepository repository;
    late CreateMerchantUseCase useCase;

    setUp(() {
      repository = _FakeMerchantRepository();
      useCase = CreateMerchantUseCase(repository);
    });

    test('should create merchant successfully when all fields are valid', () async {
      repository.setMerchantExists(false);

      final result = await useCase.call(
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      expect(result.isRight, isTrue);
      final merchant = result.rightOrNull;
      expect(merchant, isNotNull);
      expect(merchant!.name, 'Test Business');
      expect(merchant.email, 'test@example.com');
      expect(merchant.phone, '+33612345678');
      expect(merchant.city, 'Paris');
      expect(merchant.status, 'inactive');
    });

    test('should create merchant with optional fields', () async {
      repository.setMerchantExists(false);

      final result = await useCase.call(
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
        address: '123 Test Street',
        categories: ['Restaurant', 'Food'],
        description: 'A test business',
        hours: {'monday': {'open': '09:00', 'close': '18:00'}},
      );

      expect(result.isRight, isTrue);
      final merchant = result.rightOrNull;
      expect(merchant, isNotNull);
      expect(merchant!.address, '123 Test Street');
      expect(merchant.categories, ['Restaurant', 'Food']);
      expect(merchant.description, 'A test business');
      expect(merchant.hours, isNotNull);
    });

    test('should return error when ownerUid is empty', () async {
      final result = await useCase.call(
        ownerUid: '',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      expect(result.isLeft, isTrue);
      final failure = result.leftOrNull;
      expect(failure, isA<MerchantUnexpectedFailure>());
      expect(failure?.message, contains('Owner UID is required'));
    });

    test('should return error when name is empty', () async {
      final result = await useCase.call(
        ownerUid: 'user-123',
        name: '',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      expect(result.isLeft, isTrue);
      final failure = result.leftOrNull;
      expect(failure, isA<MerchantUnexpectedFailure>());
      expect(failure?.message, contains('Merchant name is required'));
    });

    test('should return error when email is empty', () async {
      final result = await useCase.call(
        ownerUid: 'user-123',
        name: 'Test Business',
        email: '',
        phone: '+33612345678',
        city: 'Paris',
      );

      expect(result.isLeft, isTrue);
      final failure = result.leftOrNull;
      expect(failure, isA<MerchantUnexpectedFailure>());
      expect(failure?.message, contains('Email is required'));
    });

    test('should return error when phone is empty', () async {
      final result = await useCase.call(
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '',
        city: 'Paris',
      );

      expect(result.isLeft, isTrue);
      final failure = result.leftOrNull;
      expect(failure, isA<MerchantUnexpectedFailure>());
      expect(failure?.message, contains('Phone number is required'));
    });

    test('should return error when city is empty', () async {
      final result = await useCase.call(
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: '',
      );

      expect(result.isLeft, isTrue);
      final failure = result.leftOrNull;
      expect(failure, isA<MerchantUnexpectedFailure>());
      expect(failure?.message, contains('City is required'));
    });

    test('should return error when merchant already exists', () async {
      repository.setMerchantExists(true);

      final result = await useCase.call(
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      expect(result.isLeft, isTrue);
      final failure = result.leftOrNull;
      expect(failure, isA<MerchantAlreadyExistsFailure>());
    });

    test('should return error when repository fails to check existence', () async {
      repository.setMerchantExists(false);
      repository.setShouldFailCreate(true);

      final result = await useCase.call(
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      expect(result.isLeft, isTrue);
      final failure = result.leftOrNull;
      expect(failure, isA<MerchantNetworkFailure>());
    });

    test('should return error when repository fails to create merchant', () async {
      final useCaseWithFailingCreate = CreateMerchantUseCase(
        _FailingCreateRepository(),
      );

      final result = await useCaseWithFailingCreate.call(
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      expect(result.isLeft, isTrue);
      final failure = result.leftOrNull;
      expect(failure, isA<UnableToCreateMerchantFailure>());
    });

  });
}

class _FailingCreateRepository implements MerchantRepository {
  @override
  Future<Result<bool>> merchantExists(String ownerUid) async {
    return const Right<MerchantFailure, bool>(false);
  }

  @override
  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  }) async {
    return const Left<MerchantFailure, Merchant>(
      UnableToCreateMerchantFailure(),
    );
  }

  @override
  Future<Result<Merchant?>> getMerchantByOwnerUid(String ownerUid) async {
    return const Right<MerchantFailure, Merchant?>(null);
  }

  @override
  Future<Result<Merchant?>> getMerchantById(String merchantId) async {
    return const Right<MerchantFailure, Merchant?>(null);
  }

  @override
  Future<Result<List<Merchant>>> listMerchants({int limit = 20}) async {
    return const Right<MerchantFailure, List<Merchant>>(<Merchant>[]);
  }

  @override
  Future<Result<List<Merchant>>> getMerchantsByIds(List<String> ids) async {
    return const Right<MerchantFailure, List<Merchant>>(<Merchant>[]);
  }

  @override
  Future<Result<Unit>> linkExistingMerchantToUser({
    required String merchantId,
    required String userId,
  }) async {
    return const Left<MerchantFailure, Unit>(
      UnableToCreateMerchantFailure(),
    );
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
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
  }) async {
    return const Left<MerchantFailure, Merchant>(
      UnableToCreateMerchantFailure(),
    );
  }
}

