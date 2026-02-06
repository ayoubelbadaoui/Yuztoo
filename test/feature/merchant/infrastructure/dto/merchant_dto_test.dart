import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/dto/merchant_dto.dart';

void main() {
  group('MerchantDto', () {
    test('should convert domain entity to DTO', () {
      final merchant = Merchant(
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

      final dto = MerchantDto.fromDomain(merchant);

      expect(dto.id, merchant.id);
      expect(dto.ownerUid, merchant.ownerUid);
      expect(dto.name, merchant.name);
      expect(dto.email, merchant.email);
      expect(dto.phone, merchant.phone);
      expect(dto.city, merchant.city);
      expect(dto.address, merchant.address);
      expect(dto.categories, merchant.categories);
      expect(dto.description, merchant.description);
      expect(dto.status, merchant.status);
    });

    test('should convert DTO to domain entity', () {
      final dto = MerchantDto(
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

      final merchant = dto.toDomain();

      expect(merchant.id, dto.id);
      expect(merchant.ownerUid, dto.ownerUid);
      expect(merchant.name, dto.name);
      expect(merchant.email, dto.email);
      expect(merchant.phone, dto.phone);
      expect(merchant.city, dto.city);
      expect(merchant.address, dto.address);
      expect(merchant.categories, dto.categories);
      expect(merchant.description, dto.description);
      expect(merchant.status, dto.status);
    });

    test('should convert to Firestore map without id field', () {
      final dto = MerchantDto(
        id: 'merchant-123',
        ownerUid: 'user-456',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      final firestoreMap = dto.toFirestore();

      // ID should not be in the map (it's the document ID)
      expect(firestoreMap.containsKey('id'), isFalse);
      expect(firestoreMap['owner_uid'], 'user-456');
      expect(firestoreMap['name'], 'Test Business');
      expect(firestoreMap['email'], 'test@example.com');
      expect(firestoreMap['phone'], '+33612345678');
      expect(firestoreMap['city'], 'Paris');
      expect(firestoreMap['status'], 'active');
    });

    test('should include optional fields in Firestore map when present', () {
      final dto = MerchantDto(
        id: 'merchant-123',
        ownerUid: 'user-456',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
        address: '123 Test Street',
        categories: ['Restaurant'],
        description: 'A test',
        hours: {'monday': {'open': '09:00'}},
      );

      final firestoreMap = dto.toFirestore();

      expect(firestoreMap['address'], '123 Test Street');
      expect(firestoreMap['categories'], ['Restaurant']);
      expect(firestoreMap['description'], 'A test');
      expect(firestoreMap['hours'], {'monday': {'open': '09:00'}});
    });

    test('should exclude optional fields from Firestore map when null', () {
      final dto = MerchantDto(
        id: 'merchant-123',
        ownerUid: 'user-456',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      final firestoreMap = dto.toFirestore();

      expect(firestoreMap.containsKey('address'), isFalse);
      expect(firestoreMap.containsKey('categories'), isFalse);
      expect(firestoreMap.containsKey('description'), isFalse);
      expect(firestoreMap.containsKey('hours'), isFalse);
    });

    test('should use server timestamp for created_at when null', () {
      final dto = MerchantDto(
        id: 'merchant-123',
        ownerUid: 'user-456',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
      );

      final firestoreMap = dto.toFirestore();

      expect(firestoreMap['created_at'], isA<FieldValue>());
      expect(firestoreMap['updated_at'], isA<FieldValue>());
    });

    test('should use provided timestamp for created_at when available', () {
      final now = DateTime.now();
      final dto = MerchantDto(
        id: 'merchant-123',
        ownerUid: 'user-456',
        name: 'Test Business',
        email: 'test@example.com',
        phone: '+33612345678',
        city: 'Paris',
        createdAt: now,
      );

      final firestoreMap = dto.toFirestore();

      expect(firestoreMap['created_at'], isA<Timestamp>());
      final timestamp = firestoreMap['created_at'] as Timestamp;
      expect(timestamp.toDate(), now);
    });
  });
}

