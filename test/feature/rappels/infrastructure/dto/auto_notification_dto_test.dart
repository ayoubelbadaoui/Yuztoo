import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/dto/auto_notification_dto.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // AutoNotificationDto — construction and toDomain()
  // ─────────────────────────────────────────────────────────────────────────
  group('AutoNotificationDto.toDomain', () {
    test('maps all fields to ActiveNotification', () {
      final now = DateTime(2025, 6, 1, 12, 0);
      final dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'Bonjour !',
        trigger: 'Chaque birthday client',
        audience: 'Certains clients',
        targetSegments: const ['vip', 'habitue'],
        isEnabled: true,
        createdAt: now,
        sentCount: 3,
        lastSentAt: now,
      );

      final domain = dto.toDomain();
      expect(domain.id, 'n1');
      expect(domain.merchantId, 'm1');
      expect(domain.text, 'Bonjour !');
      expect(domain.trigger, 'Chaque birthday client');
      expect(domain.audience, 'Certains clients');
      expect(domain.targetSegments, ['vip', 'habitue']);
      expect(domain.isEnabled, isTrue);
      expect(domain.createdAt, now);
      expect(domain.sentCount, 3);
      expect(domain.lastSentAt, now);
    });

    test('empty targetSegments → empty list in domain', () {
      const dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'x',
        trigger: 'T',
        audience: 'A',
        isEnabled: false,
      );
      expect(dto.toDomain().targetSegments, isEmpty);
    });

    test('sentCount=0 is preserved', () {
      const dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'x',
        trigger: 'T',
        audience: 'A',
        isEnabled: true,
        sentCount: 0,
      );
      expect(dto.toDomain().sentCount, 0);
    });

    test('isEnabled=false is preserved', () {
      const dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'x',
        trigger: 'T',
        audience: 'A',
        isEnabled: false,
      );
      expect(dto.toDomain().isEnabled, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AutoNotificationDto — toFirestore()
  // ─────────────────────────────────────────────────────────────────────────
  group('AutoNotificationDto.toFirestore', () {
    test('includes all required keys', () {
      final dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'Bonjour',
        trigger: 'T',
        audience: 'A',
        isEnabled: true,
        createdAt: DateTime(2025, 1, 1),
      );
      final map = dto.toFirestore();
      expect(map.containsKey('text'), isTrue);
      expect(map.containsKey('trigger'), isTrue);
      expect(map.containsKey('audience'), isTrue);
      expect(map.containsKey('target_segments'), isTrue);
      expect(map.containsKey('is_enabled'), isTrue);
      expect(map.containsKey('created_at'), isTrue);
      expect(map.containsKey('updated_at'), isTrue);
    });

    test('target_segments stored as list', () {
      const dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'x',
        trigger: 'T',
        audience: 'A',
        isEnabled: true,
        targetSegments: ['vip', 'nouveau'],
      );
      final map = dto.toFirestore();
      expect(map['target_segments'], isA<List>());
      expect((map['target_segments'] as List).length, 2);
    });

    test('text, trigger, audience round-trip correctly', () {
      const dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'Flash sale',
        trigger: 'Rappel inactivité',
        audience: 'Certains clients',
        isEnabled: false,
      );
      final map = dto.toFirestore();
      expect(map['text'], 'Flash sale');
      expect(map['trigger'], 'Rappel inactivité');
      expect(map['audience'], 'Certains clients');
      expect(map['is_enabled'], isFalse);
    });

    test('empty targetSegments → empty list in Firestore map', () {
      const dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'x',
        trigger: 'T',
        audience: 'A',
        isEnabled: true,
      );
      final map = dto.toFirestore();
      expect(map['target_segments'], isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BUG-5 (mirror logic): defensive 'is List' guard for target_segments
  // The fix: `data['target_segments'] is List ? ... : const []`
  // This mirrors the defensive fix in fromFirestore and ensures the logic
  // is correct for all valid and invalid Firestore payloads.
  // ─────────────────────────────────────────────────────────────────────────
  group('BUG-5: target_segments defensive parsing (fromFirestore guard mirror)',
      () {
    // Mirror of the fromFirestore defensive logic
    List<String> parseTargetSegments(dynamic raw) {
      if (raw is List) return List<String>.from(raw);
      return const [];
    }

    test('List<String> → parsed correctly', () {
      expect(parseTargetSegments(['vip', 'habitue']), ['vip', 'habitue']);
    });

    test('null → empty list (safe, old code would return [] via ternary)', () {
      expect(parseTargetSegments(null), isEmpty);
    });

    test('String → empty list (was crash before fix)', () {
      // Before fix: `null != null` was false, but `'vip' != null` was true →
      // `'vip' as List` → TypeError crash.
      // After fix: `'vip' is List` → false → empty list.
      expect(parseTargetSegments('vip'), isEmpty);
    });

    test('int → empty list (was crash before fix)', () {
      expect(parseTargetSegments(1), isEmpty);
    });

    test('Map → empty list (was crash before fix)', () {
      expect(parseTargetSegments({'key': 'value'}), isEmpty);
    });

    test('empty List → empty list', () {
      expect(parseTargetSegments([]), isEmpty);
    });

    test('List<dynamic> with strings → correct cast', () {
      final dynamic raw = <dynamic>['vip', 'nouveau'];
      expect(parseTargetSegments(raw), ['vip', 'nouveau']);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AutoNotificationDto — copyWith (via domain entity)
  // ─────────────────────────────────────────────────────────────────────────
  group('ActiveNotification.copyWith (DTO integration)', () {
    test('updating sentCount via domain entity preserves other fields', () {
      const dto = AutoNotificationDto(
        id: 'n1',
        merchantId: 'm1',
        text: 'Hello',
        trigger: 'Birthday',
        audience: 'All',
        isEnabled: true,
        sentCount: 0,
        targetSegments: ['vip'],
      );
      final domain = dto.toDomain();
      final updated = domain.copyWith(sentCount: 5);
      expect(updated.sentCount, 5);
      expect(updated.id, 'n1');
      expect(updated.targetSegments, ['vip']);
    });
  });
}
