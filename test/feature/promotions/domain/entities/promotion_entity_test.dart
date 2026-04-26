import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';

void main() {
  final basePromo = Promotion(
    id: 'p1',
    merchantId: 'm1',
    title: '20% de réduction',
    subtitle: 'Ce weekend seulement',
    dateFrom: DateTime(2025, 6, 1),
    dateTo: DateTime(2025, 6, 30),
    selectedClientType: ClientType.gratuit,
    isOnline: true,
  );

  group('Promotion entity', () {
    test('viewCount defaults to 0', () {
      expect( basePromo.viewCount, 0);
    });

    test('copyWith updates viewCount', () {
      final updated = basePromo.copyWith(viewCount: 42);
      expect(updated.viewCount, 42);
      expect(updated.id, basePromo.id);
    });

    test('copyWith isOnline toggle preserves other fields', () {
      final toggled = basePromo.copyWith(isOnline: false);
      expect(toggled.isOnline, false);
      expect(toggled.title, basePromo.title);
      expect(toggled.viewCount, 0);
    });

    test('imagePath and imageUrl default to null', () {
      expect( basePromo.imagePath, isNull);
      expect( basePromo.imageUrl, isNull);
    });

    test('copyWith imageUrl sets url', () {
      final withImage = basePromo.copyWith(imageUrl: 'https://cdn.example/img.png');
      expect(withImage.imageUrl, 'https://cdn.example/img.png');
    });

    test('ClientType.gratuit is default', () {
      expect( basePromo.selectedClientType, ClientType.gratuit);
    });

    test('ClientTypeX.fromString maps correctly', () {
      expect(ClientTypeX.fromString('premium'), ClientType.premium);
      expect(ClientTypeX.fromString('payant'), ClientType.payant);
      expect(ClientTypeX.fromString('gratuit'), ClientType.gratuit);
      expect(ClientTypeX.fromString(null), ClientType.gratuit);
      expect(ClientTypeX.fromString('unknown'), ClientType.gratuit);
    });

    test('ClientType value strings are correct', () {
      expect(ClientType.gratuit.value, 'gratuit');
      expect(ClientType.premium.value, 'premium');
      expect(ClientType.payant.value, 'payant');
    });

    test('expired promotion: dateTo in the past', () {
      final expired = basePromo.copyWith(
        dateTo: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expired.dateTo.isBefore(DateTime.now()), isTrue);
    });

    test('active promotion: dateTo in the future', () {
      final active = basePromo.copyWith(
        dateTo: DateTime.now().add(const Duration(days: 10)),
      );
      expect(active.dateTo.isAfter(DateTime.now()), isTrue);
    });
  });
}
