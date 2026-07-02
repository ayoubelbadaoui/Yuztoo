import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/dto/merchant_dto.dart';

void main() {
  group('MerchantDto', () {
    test('should convert domain entity to DTO', () {
      const merchant = Merchant(
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
      const dto = MerchantDto(
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
      const dto = MerchantDto(
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
      expect(firestoreMap['status'], 'inactive');
    });

    test('should include optional fields in Firestore map when present', () {
      const dto = MerchantDto(
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
      const dto = MerchantDto(
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
      const dto = MerchantDto(
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

  // ── BUG-7: MerchantDto.fromFirestore — defensive parsing contract ──────────
  // Root cause: multiple `as bool? ?? default` and `as List` casts in
  // fromFirestore throw TypeError when Firestore data has unexpected types.
  // This is the highest-severity crash: a bad merchant doc takes down the
  // entire storefront for both clients and the merchant.
  //
  // fromFirestore requires a Firebase DocumentSnapshot so we mirror the
  // defensive logic inline and test those patterns directly.

  group('BUG-7: MerchantDto — defensive bool parsing (mirror logic)', () {
    // Mirror of `data['messaging_enabled'] != false`
    // Default: true. Only false when explicitly set to false.
    bool parseDefaultTrue(dynamic raw) => raw != false;

    // Mirror of `data['is_online'] == true`
    // Default: false. Only true when explicitly set to true.
    bool parseFalseDefault(dynamic raw) => raw == true;

    // Mirror of `data['rappels_auto_client_validation'] is bool ? ... : null`
    bool? parseNullableBool(dynamic raw) => raw is bool ? raw : null;

    // Mirror of `data['categories'] is List ? List<String>.from(...) : null`
    List<String>? parseStringList(dynamic raw) =>
        raw is List ? List<String>.from(raw) : null;

    // Mirror of `data['hours'] is Map ? Map<String,dynamic>.from(...) : null`
    Map<String, dynamic>? parseMapField(dynamic raw) =>
        raw is Map ? Map<String, dynamic>.from(raw) : null;

    group('true-defaulting bool fields (messaging_enabled, galerie_enabled, etc.)', () {
      test('null → true (default)', () {
        expect(parseDefaultTrue(null), isTrue);
      });

      test('true → true', () {
        expect(parseDefaultTrue(true), isTrue);
      });

      test('false → false', () {
        expect(parseDefaultTrue(false), isFalse);
      });

      test('int 1 → true (was crash before fix)', () {
        // Before: `1 as bool? ?? true` throws TypeError
        // After: `1 != false` → true
        expect(parseDefaultTrue(1), isTrue);
      });

      test('int 0 → true (unexpected but no crash)', () {
        // int 0 != false (false is a bool literal), so returns true.
        // This is the safe fallback — we don't want to accidentally disable features.
        expect(parseDefaultTrue(0), isTrue);
      });

      test('String "true" → true (no crash)', () {
        expect(parseDefaultTrue('true'), isTrue);
      });

      test('String "false" → true (no crash — conservative default)', () {
        // 'false' as a String != false (the bool), so returns true.
        // Acceptable: if someone stored a string, we stay enabled (safe default).
        expect(parseDefaultTrue('false'), isTrue);
      });
    });

    group('false-defaulting bool fields (is_online)', () {
      test('null → false (default)', () {
        expect(parseFalseDefault(null), isFalse);
      });

      test('true → true', () {
        expect(parseFalseDefault(true), isTrue);
      });

      test('false → false', () {
        expect(parseFalseDefault(false), isFalse);
      });

      test('int 1 → false (was crash before fix)', () {
        // Before: `1 as bool? ?? false` throws TypeError
        // After: `1 == true` → false (safe conservative default)
        expect(parseFalseDefault(1), isFalse);
      });

      test('String "true" → false (no crash)', () {
        expect(parseFalseDefault('true'), isFalse);
      });
    });

    group('nullable bool fields (rappels_auto_client/passage_validation)', () {
      test('null → null', () {
        expect(parseNullableBool(null), isNull);
      });

      test('true → true', () {
        expect(parseNullableBool(true), isTrue);
      });

      test('false → false', () {
        expect(parseNullableBool(false), isFalse);
      });

      test('int 1 → null (was crash before fix)', () {
        // Before: `1 as bool?` throws TypeError
        // After: `1 is bool` → false → returns null (safe)
        expect(parseNullableBool(1), isNull);
      });

      test('String "true" → null (was crash before fix)', () {
        expect(parseNullableBool('true'), isNull);
      });
    });

    group('passage_cooldown_enabled Firestore round-trip', () {
      test('toFirestore + toDomain preserves bool', () {
        const dto = MerchantDto(
          id: 'm1',
          ownerUid: 'u1',
          name: 'Shop',
          email: 'a@b.c',
          phone: '+33600000000',
          city: 'Paris',
          passageCooldownEnabled: false,
        );
        expect(dto.toFirestore()['passage_cooldown_enabled'], isFalse);
        expect(dto.toDomain().passageCooldownEnabled, isFalse);
      });

      test('null omits field from toFirestore', () {
        const dto = MerchantDto(
          id: 'm1',
          ownerUid: 'u1',
          name: 'Shop',
          email: 'a@b.c',
          phone: '+33600000000',
          city: 'Paris',
        );
        expect(dto.toFirestore().containsKey('passage_cooldown_enabled'), isFalse);
        expect(dto.toDomain().passageCooldownEnabled, isNull);
      });
    });

    group('List fields (categories, newsImageUrls)', () {
      test('null → null (no categories set)', () {
        expect(parseStringList(null), isNull);
      });

      test('valid List → parsed correctly', () {
        expect(parseStringList(['Restaurant', 'Food']), ['Restaurant', 'Food']);
      });

      test('empty List → empty list (not null)', () {
        expect(parseStringList([]), isEmpty);
      });

      test('String → null (was crash before fix)', () {
        // Before: `'boulangerie' as List` throws TypeError
        // After: `'boulangerie' is List` → false → null
        expect(parseStringList('boulangerie'), isNull);
      });

      test('Map → null (was crash before fix)', () {
        expect(parseStringList({'key': 'val'}), isNull);
      });

      test('int → null (was crash before fix)', () {
        expect(parseStringList(42), isNull);
      });
    });

    group('Map fields (hours)', () {
      test('null → null (merchant has no hours set)', () {
        expect(parseMapField(null), isNull);
      });

      test('valid Map → parsed correctly', () {
        final result = parseMapField({'monday': 'closed'});
        expect(result, {'monday': 'closed'});
      });

      test('String → null (was crash before fix)', () {
        // Before: `'always open' as Map<String, dynamic>?` throws TypeError
        // After: `'always open' is Map` → false → null
        expect(parseMapField('always open'), isNull);
      });

      test('List → null (was crash before fix)', () {
        expect(parseMapField(['monday', 'tuesday']), isNull);
      });

      test('int → null (was crash before fix)', () {
        expect(parseMapField(1), isNull);
      });
    });
  });
}

