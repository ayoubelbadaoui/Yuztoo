import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';
import 'package:flutter_yuztoo/feature/promotions/infrastructure/dto/promotion_dto.dart';

// ── Minimal fake DocumentSnapshot ──────────────────────────────────────────

// ignore: subtype_of_sealed_class
class _FakeDocSnap implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocSnap(this._id, this._data);

  final String _id;
  final Map<String, dynamic>? _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  // Unimplemented members required by the interface — not used in DTO
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ── Helpers ─────────────────────────────────────────────────────────────────

Map<String, dynamic> _validData({
  String title = 'Test promo',
  String subtitle = 'Description',
  dynamic dateFrom,
  dynamic dateTo,
  String clientType = 'gratuit',
  bool isOnline = true,
  String? imageUrl,
  int viewCount = 0,
  List<dynamic>? targetSegments,
  String? diffusionZone,
}) {
  final now = DateTime(2025, 6, 1);
  return {
    'title': title,
    'subtitle': subtitle,
    'date_from': Timestamp.fromDate(dateFrom as DateTime? ?? now),
    'date_to': Timestamp.fromDate(dateTo as DateTime? ?? now.add(const Duration(days: 14))),
    'client_type': clientType,
    'is_online': isOnline,
    if (imageUrl != null) 'image_url': imageUrl,
    'view_count': viewCount,
    if (targetSegments != null) 'target_segments': targetSegments,
    if (diffusionZone != null) 'diffusion_zone': diffusionZone,
  };
}

DocumentSnapshot<Map<String, dynamic>> _doc(
  String id,
  Map<String, dynamic>? data,
) =>
    _FakeDocSnap(id, data);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('PromotionDto.fromFirestore', () {
    test('returns null when document data is null (no throw)', () {
      final dto = PromotionDto.fromFirestore(_doc('p1', null), 'm1');
      expect(dto, isNull);
    });

    test('parses a complete valid document', () {
      final dateFrom = DateTime(2025, 6, 1);
      final dateTo = DateTime(2025, 6, 30);
      final dto = PromotionDto.fromFirestore(
        _doc(
          'p42',
          _validData(
            title: 'Soldes',
            subtitle: '-20%',
            dateFrom: dateFrom,
            dateTo: dateTo,
            clientType: 'premium',
            isOnline: true,
            imageUrl: 'https://example.com/img.jpg',
            viewCount: 7,
            targetSegments: ['vip', 'habitue'],
            diffusionZone: null,
          ),
        ),
        'm1',
      );

      expect(dto, isNotNull);
      expect(dto!.id, 'p42');
      expect(dto.merchantId, 'm1');
      expect(dto.title, 'Soldes');
      expect(dto.subtitle, '-20%');
      expect(dto.dateFrom, dateFrom);
      expect(dto.dateTo, dateTo);
      expect(dto.clientType, 'premium');
      expect(dto.isOnline, isTrue);
      expect(dto.imageUrl, 'https://example.com/img.jpg');
      expect(dto.viewCount, 7);
      expect(dto.targetSegments, ['vip', 'habitue']);
      expect(dto.diffusionZone, isNull);
    });

    test('applies defaults when optional fields are missing', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', {'title': 'T', 'subtitle': 'S'}),
        'm1',
      );
      expect(dto, isNotNull);
      expect(dto!.clientType, 'gratuit');
      expect(dto.isOnline, isFalse);
      expect(dto.imageUrl, isNull);
      expect(dto.viewCount, 0);
      expect(dto.targetSegments, isEmpty);
      expect(dto.diffusionZone, isNull);
    });

    test('handles target_segments being null gracefully', () {
      final data = _validData();
      data.remove('target_segments');
      final dto = PromotionDto.fromFirestore(_doc('p1', data), 'm1');
      expect(dto!.targetSegments, isEmpty);
    });

    test('handles target_segments with non-string items gracefully', () {
      final data = _validData(targetSegments: ['vip', 42, null, 'habitue']);
      final dto = PromotionDto.fromFirestore(_doc('p1', data), 'm1');
      // whereType<String> filters non-strings
      expect(dto!.targetSegments, ['vip', 'habitue']);
    });

    test('parses payant promo with diffusion_zone', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(
          clientType: 'payant',
          diffusionZone: 'ville',
          targetSegments: [],
        )),
        'm1',
      );
      expect(dto!.diffusionZone, 'ville');
      expect(dto.targetSegments, isEmpty);
    });

    test('handles unknown clientType without throwing', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(clientType: 'unknown_type')),
        'm1',
      );
      // ClientTypeX.fromString defaults unknown to gratuit
      expect(dto!.toDomain().selectedClientType, ClientType.gratuit);
    });
  });

  group('PromotionDto.toDomain', () {
    test('maps gratuit clientType correctly', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(clientType: 'gratuit')),
        'm1',
      );
      expect(dto!.toDomain().selectedClientType, ClientType.gratuit);
    });

    test('maps premium clientType correctly', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(clientType: 'premium')),
        'm1',
      );
      expect(dto!.toDomain().selectedClientType, ClientType.premium);
    });

    test('maps payant clientType correctly', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(clientType: 'payant')),
        'm1',
      );
      expect(dto!.toDomain().selectedClientType, ClientType.payant);
    });

    test('maps PromotionZone.ville from diffusion_zone', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(clientType: 'payant', diffusionZone: 'ville')),
        'm1',
      );
      expect(dto!.toDomain().diffusionZone, PromotionZone.ville);
    });

    test('maps PromotionZone.quartier from diffusion_zone', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(clientType: 'payant', diffusionZone: 'quartier')),
        'm1',
      );
      expect(dto!.toDomain().diffusionZone, PromotionZone.quartier);
    });

    test('maps PromotionZone.proche from diffusion_zone', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(clientType: 'payant', diffusionZone: 'proche')),
        'm1',
      );
      expect(dto!.toDomain().diffusionZone, PromotionZone.proche);
    });

    test('null diffusion_zone maps to null', () {
      final dto = PromotionDto.fromFirestore(_doc('p1', _validData()), 'm1');
      expect(dto!.toDomain().diffusionZone, isNull);
    });

    test('targetSegments forwarded to domain entity', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(
          clientType: 'premium',
          targetSegments: ['vip', 'soutien'],
        )),
        'm1',
      );
      expect(dto!.toDomain().targetSegments, ['vip', 'soutien']);
    });

    test('viewCount forwarded to domain entity', () {
      final dto = PromotionDto.fromFirestore(
        _doc('p1', _validData(viewCount: 42)),
        'm1',
      );
      expect(dto!.toDomain().viewCount, 42);
    });
  });

  group('PromotionDto.toFirestore', () {
    test('contains all required fields', () {
      final dto = PromotionDto(
        id: 'p1',
        merchantId: 'm1',
        title: 'Promo',
        subtitle: 'desc',
        dateFrom: DateTime(2025, 6, 1),
        dateTo: DateTime(2025, 6, 30),
        clientType: 'gratuit',
        isOnline: true,
      );
      final map = dto.toFirestore();
      expect(map.containsKey('title'), isTrue);
      expect(map.containsKey('subtitle'), isTrue);
      expect(map.containsKey('date_from'), isTrue);
      expect(map.containsKey('date_to'), isTrue);
      expect(map.containsKey('client_type'), isTrue);
      expect(map.containsKey('is_online'), isTrue);
      expect(map.containsKey('target_segments'), isTrue);
    });

    test('omits image_url when null', () {
      final dto = PromotionDto(
        id: 'p1', merchantId: 'm1', title: 'T', subtitle: 'S',
        dateFrom: DateTime(2025, 1, 1), dateTo: DateTime(2025, 12, 31),
        clientType: 'gratuit', isOnline: false,
      );
      expect(dto.toFirestore().containsKey('image_url'), isFalse);
    });

    test('includes image_url when set', () {
      final dto = PromotionDto(
        id: 'p1', merchantId: 'm1', title: 'T', subtitle: 'S',
        dateFrom: DateTime(2025, 1, 1), dateTo: DateTime(2025, 12, 31),
        clientType: 'gratuit', isOnline: true,
        imageUrl: 'https://example.com/promo.jpg',
      );
      expect(dto.toFirestore()['image_url'], 'https://example.com/promo.jpg');
    });

    test('omits diffusion_zone when null', () {
      final dto = PromotionDto(
        id: 'p1', merchantId: 'm1', title: 'T', subtitle: 'S',
        dateFrom: DateTime(2025, 1, 1), dateTo: DateTime(2025, 12, 31),
        clientType: 'payant', isOnline: true,
      );
      expect(dto.toFirestore().containsKey('diffusion_zone'), isFalse);
    });

    test('includes diffusion_zone when set', () {
      final dto = PromotionDto(
        id: 'p1', merchantId: 'm1', title: 'T', subtitle: 'S',
        dateFrom: DateTime(2025, 1, 1), dateTo: DateTime(2025, 12, 31),
        clientType: 'payant', isOnline: true,
        diffusionZone: 'ville',
      );
      expect(dto.toFirestore()['diffusion_zone'], 'ville');
    });

    test('target_segments always written (even empty)', () {
      final dto = PromotionDto(
        id: 'p1', merchantId: 'm1', title: 'T', subtitle: 'S',
        dateFrom: DateTime(2025, 1, 1), dateTo: DateTime(2025, 12, 31),
        clientType: 'gratuit', isOnline: false,
      );
      expect(dto.toFirestore()['target_segments'], isEmpty);
    });

    test('does not write view_count (no overwrite of server increments)', () {
      final dto = PromotionDto(
        id: 'p1', merchantId: 'm1', title: 'T', subtitle: 'S',
        dateFrom: DateTime(2025, 1, 1), dateTo: DateTime(2025, 12, 31),
        clientType: 'gratuit', isOnline: true, viewCount: 99,
      );
      expect(dto.toFirestore().containsKey('view_count'), isFalse);
    });
  });

  group('PromotionZone enum', () {
    test('estimatedReach values are positive', () {
      for (final zone in PromotionZone.values) {
        expect(zone.estimatedReach, greaterThan(0));
      }
    });

    test('fromString roundtrips all values', () {
      for (final zone in PromotionZone.values) {
        expect(PromotionZoneX.fromString(zone.value), zone);
      }
    });

    test('fromString returns null for unknown value', () {
      expect(PromotionZoneX.fromString('unknown'), isNull);
    });

    test('fromString returns null for null input', () {
      expect(PromotionZoneX.fromString(null), isNull);
    });
  });

  group('ClientType enum', () {
    test('fromString roundtrips all values', () {
      for (final type in ClientType.values) {
        expect(ClientTypeX.fromString(type.value), type);
      }
    });

    test('fromString defaults to gratuit for unknown', () {
      expect(ClientTypeX.fromString('bogus'), ClientType.gratuit);
    });

    test('fromString defaults to gratuit for null', () {
      expect(ClientTypeX.fromString(null), ClientType.gratuit);
    });
  });
}
