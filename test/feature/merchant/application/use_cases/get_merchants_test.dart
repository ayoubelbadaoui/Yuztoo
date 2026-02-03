import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/feature/merchant/application/use_cases/get_merchants.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/merchant_failure.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/repositories/merchant_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMerchantRepository extends Mock implements MerchantRepository {}

void main() {
  group('GetMerchants', () {
    late MockMerchantRepository mockRepository;
    late GetMerchants useCase;

    setUp(() {
      mockRepository = MockMerchantRepository();
      useCase = GetMerchants(mockRepository);
    });

    test('should return list of merchants when found', () async {
      // Arrange
      final merchants = [
        Merchant(
          id: 'merchant-1',
          ownerUid: 'user-1',
          name: 'Business 1',
          email: 'business1@example.com',
          phone: '+33612345678',
          city: 'Paris',
          status: 'active',
        ),
        Merchant(
          id: 'merchant-2',
          ownerUid: 'user-2',
          name: 'Business 2',
          email: 'business2@example.com',
          phone: '+33612345679',
          city: 'Paris',
          status: 'active',
        ),
      ];

      when(() => mockRepository.getMerchants(city: any(named: 'city')))
          .thenAnswer((_) async => Right<MerchantFailure, List<Merchant>>(merchants));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isRight, isTrue);
      final returnedMerchants = result.fold((l) => null, (r) => r);
      expect(returnedMerchants, isNotNull);
      expect(returnedMerchants!.length, 2);
      expect(returnedMerchants[0].name, 'Business 1');
      expect(returnedMerchants[1].name, 'Business 2');

      verify(() => mockRepository.getMerchants(city: null)).called(1);
    });

    test('should return empty list when no merchants found', () async {
      // Arrange
      when(() => mockRepository.getMerchants(city: any(named: 'city')))
          .thenAnswer((_) async => const Right<MerchantFailure, List<Merchant>>([]));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isRight, isTrue);
      final returnedMerchants = result.fold((l) => null, (r) => r);
      expect(returnedMerchants, isNotNull);
      expect(returnedMerchants!.isEmpty, isTrue);
    });

    test('should filter by city when provided', () async {
      // Arrange
      final merchants = [
        Merchant(
          id: 'merchant-1',
          ownerUid: 'user-1',
          name: 'Business 1',
          email: 'business1@example.com',
          phone: '+33612345678',
          city: 'Paris',
          status: 'active',
        ),
      ];

      when(() => mockRepository.getMerchants(city: any(named: 'city')))
          .thenAnswer((_) async => Right<MerchantFailure, List<Merchant>>(merchants));

      // Act
      final result = await useCase.call(city: 'Paris');

      // Assert
      expect(result.isRight, isTrue);
      final returnedMerchants = result.fold((l) => null, (r) => r);
      expect(returnedMerchants, isNotNull);
      expect(returnedMerchants!.length, 1);

      verify(() => mockRepository.getMerchants(city: 'Paris')).called(1);
    });

    test('should handle network failure', () async {
      // Arrange
      when(() => mockRepository.getMerchants(city: any(named: 'city')))
          .thenAnswer((_) async => const Left<MerchantFailure, List<Merchant>>(
                MerchantNetworkFailure(),
              ));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isLeft, isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<MerchantNetworkFailure>());
    });

    test('should handle unexpected failure', () async {
      // Arrange
      when(() => mockRepository.getMerchants(city: any(named: 'city')))
          .thenAnswer((_) async => const Left<MerchantFailure, List<Merchant>>(
                MerchantUnexpectedFailure(message: 'Unexpected error'),
              ));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isLeft, isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<MerchantUnexpectedFailure>());
      expect(failure?.message, 'Unexpected error');
    });

    test('should handle empty city filter', () async {
      // Arrange
      when(() => mockRepository.getMerchants(city: any(named: 'city')))
          .thenAnswer((_) async => const Right<MerchantFailure, List<Merchant>>([]));

      // Act
      final result = await useCase.call(city: '');

      // Assert
      expect(result.isRight, isTrue);
      verify(() => mockRepository.getMerchants(city: '')).called(1);
    });

    test('should handle large list of merchants', () async {
      // Arrange
      final merchants = List.generate(
        100,
        (i) => Merchant(
          id: 'merchant-$i',
          ownerUid: 'user-$i',
          name: 'Business $i',
          email: 'business$i@example.com',
          phone: '+33612345678',
          city: 'Paris',
          status: 'active',
        ),
      );

      when(() => mockRepository.getMerchants(city: any(named: 'city')))
          .thenAnswer((_) async => Right<MerchantFailure, List<Merchant>>(merchants));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isRight, isTrue);
      final returnedMerchants = result.fold((l) => null, (r) => r);
      expect(returnedMerchants, isNotNull);
      expect(returnedMerchants!.length, 100);
    });
  });
}

