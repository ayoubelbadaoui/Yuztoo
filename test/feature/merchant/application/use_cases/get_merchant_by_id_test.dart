import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/feature/merchant/application/use_cases/get_merchant_by_id.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/merchant_failure.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/repositories/merchant_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMerchantRepository extends Mock implements MerchantRepository {}

void main() {
  group('GetMerchantById', () {
    late MockMerchantRepository mockRepository;
    late GetMerchantById useCase;

    setUp(() {
      mockRepository = MockMerchantRepository();
      useCase = GetMerchantById(mockRepository);
    });

    test('should return merchant when found', () async {
      // Arrange
      final merchant = Merchant(
        id: 'merchant-123',
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
        status: 'active',
      );

      when(() => mockRepository.getMerchantById(any()))
          .thenAnswer((_) async => Right<MerchantFailure, Merchant?>(merchant));

      // Act
      final result = await useCase.call('merchant-123');

      // Assert
      expect(result.isRight, isTrue);
      final returnedMerchant = result.fold((l) => null, (r) => r);
      expect(returnedMerchant, isNotNull);
      expect(returnedMerchant!.id, 'merchant-123');
      expect(returnedMerchant.name, 'Test Business');

      verify(() => mockRepository.getMerchantById('merchant-123')).called(1);
    });

    test('should return null when merchant not found', () async {
      // Arrange
      when(() => mockRepository.getMerchantById(any()))
          .thenAnswer((_) async => const Right<MerchantFailure, Merchant?>(null));

      // Act
      final result = await useCase.call('non-existent');

      // Assert
      expect(result.isRight, isTrue);
      final returnedMerchant = result.fold((l) => null, (r) => r);
      expect(returnedMerchant, isNull);

      verify(() => mockRepository.getMerchantById('non-existent')).called(1);
    });

    test('should return null when merchantId is empty', () async {
      // Act
      final result = await useCase.call('');

      // Assert
      expect(result.isRight, isTrue);
      final returnedMerchant = result.fold((l) => null, (r) => r);
      expect(returnedMerchant, isNull);

      verifyNever(() => mockRepository.getMerchantById(any()));
    });

    test('should handle network failure', () async {
      // Arrange
      when(() => mockRepository.getMerchantById(any()))
          .thenAnswer((_) async => const Left<MerchantFailure, Merchant?>(
                MerchantNetworkFailure(),
              ));

      // Act
      final result = await useCase.call('merchant-123');

      // Assert
      expect(result.isLeft, isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<MerchantNetworkFailure>());

      verify(() => mockRepository.getMerchantById('merchant-123')).called(1);
    });

    test('should handle unexpected failure', () async {
      // Arrange
      when(() => mockRepository.getMerchantById(any()))
          .thenAnswer((_) async => const Left<MerchantFailure, Merchant?>(
                MerchantUnexpectedFailure(message: 'Unexpected error'),
              ));

      // Act
      final result = await useCase.call('merchant-123');

      // Assert
      expect(result.isLeft, isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<MerchantUnexpectedFailure>());
      expect(failure?.message, 'Unexpected error');
    });

    test('should handle merchant with all optional fields', () async {
      // Arrange
      final merchant = Merchant(
        id: 'merchant-123',
        ownerUid: 'user-123',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
        address: '123 Test Street',
        categories: ['restaurant', 'food'],
        description: 'A test business',
        hours: {'monday': {'open': '09:00', 'close': '18:00'}},
        status: 'active',
      );

      when(() => mockRepository.getMerchantById(any()))
          .thenAnswer((_) async => Right<MerchantFailure, Merchant?>(merchant));

      // Act
      final result = await useCase.call('merchant-123');

      // Assert
      expect(result.isRight, isTrue);
      final returnedMerchant = result.fold((l) => null, (r) => r);
      expect(returnedMerchant, isNotNull);
      expect(returnedMerchant!.address, '123 Test Street');
      expect(returnedMerchant.categories, ['restaurant', 'food']);
      expect(returnedMerchant.description, 'A test business');
      expect(returnedMerchant.hours, isNotNull);
    });
  });
}

