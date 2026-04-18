import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

void main() {
  group('Merchant Entity', () {
    const testMerchant = Merchant(
      id: 'merchant-123',
      ownerUid: 'user-456',
      name: 'Test Business',
      email: 'test@example.com',
      phone: '+33612345678',
      city: 'Paris',
      address: '123 Test Street',
      categories: ['Restaurant', 'Food'],
      description: 'A test business',
      status: 'active',
    );

    test('should create a merchant with all required fields', () {
      expect(testMerchant.id, 'merchant-123');
      expect(testMerchant.ownerUid, 'user-456');
      expect(testMerchant.name, 'Test Business');
      expect(testMerchant.email, 'test@example.com');
      expect(testMerchant.phone, '+33612345678');
      expect(testMerchant.city, 'Paris');
      expect(testMerchant.status, 'active');
    });

    test('should create a merchant with optional fields', () {
      expect(testMerchant.address, '123 Test Street');
      expect(testMerchant.categories, ['Restaurant', 'Food']);
      expect(testMerchant.description, 'A test business');
    });

    test('should create a merchant without optional fields', () {
      const minimalMerchant = Merchant(
        id: 'merchant-789',
        ownerUid: 'user-101',
        name: 'Minimal Business',
        email: 'minimal@example.com',
        phone: '+33698765432',
        city: 'Lyon',
      );

      expect(minimalMerchant.address, isNull);
      expect(minimalMerchant.categories, isNull);
      expect(minimalMerchant.description, isNull);
      expect(minimalMerchant.hours, isNull);
      expect(minimalMerchant.status, 'inactive'); // default: hors ligne
    });

    test('should have default status as inactive (hors ligne)', () {
      const merchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      expect(merchant.status, 'inactive');
    });

    test('should validate required fields correctly', () {
      const validMerchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      expect(validMerchant.isValid(), isTrue);
    });

    test('should return false for invalid merchant with empty id', () {
      const invalidMerchant = Merchant(
        id: '',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      expect(invalidMerchant.isValid(), isFalse);
    });

    test('should return false for invalid merchant with empty name', () {
      const invalidMerchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: '',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      expect(invalidMerchant.isValid(), isFalse);
    });

    test('should return false for invalid merchant with empty email', () {
      const invalidMerchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: '',
        phone: '+33611111111',
        city: 'Paris',
      );

      expect(invalidMerchant.isValid(), isFalse);
    });

    test('should return false for invalid merchant with empty phone', () {
      const invalidMerchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '',
        city: 'Paris',
      );

      expect(invalidMerchant.isValid(), isFalse);
    });

    test('should return false for invalid merchant with empty city', () {
      const invalidMerchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: '',
      );

      expect(invalidMerchant.isValid(), isFalse);
    });

    test('should return false when city is a UI placeholder', () {
      const invalidMerchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'À compléter',
      );

      expect(invalidMerchant.isValid(), isFalse);
    });

    test('should return false for invalid merchant with empty ownerUid', () {
      const invalidMerchant = Merchant(
        id: 'merchant-1',
        ownerUid: '',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      expect(invalidMerchant.isValid(), isFalse);
    });

    test('should be equal when all properties match', () {
      const merchant1 = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      const merchant2 = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      expect(merchant1, equals(merchant2));
      expect(merchant1.hashCode, equals(merchant2.hashCode));
    });

    test('should not be equal when properties differ', () {
      const merchant1 = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      const merchant2 = Merchant(
        id: 'merchant-2',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      expect(merchant1, isNot(equals(merchant2)));
    });

    test('should create a copy with updated fields', () {
      const original = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
      );

      final updated = original.copyWith(
        name: 'Updated Business',
        city: 'Lyon',
      );

      expect(updated.id, original.id);
      expect(updated.ownerUid, original.ownerUid);
      expect(updated.name, 'Updated Business');
      expect(updated.city, 'Lyon');
      expect(updated.email, original.email);
      expect(updated.phone, original.phone);
    });

    test('should handle timestamps', () {
      final now = DateTime.now();
      final merchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
        createdAt: now,
        updatedAt: now,
      );

      expect(merchant.createdAt, now);
      expect(merchant.updatedAt, now);
    });

    test('should handle hours map', () {
      const hours = {
        'monday': {'open': '09:00', 'close': '18:00'},
        'tuesday': {'open': '09:00', 'close': '18:00'},
      };

      const merchant = Merchant(
        id: 'merchant-1',
        ownerUid: 'user-1',
        name: 'Business',
        email: 'biz@example.com',
        phone: '+33611111111',
        city: 'Paris',
        hours: hours,
      );

      expect(merchant.hours, hours);
    });
  });
}

