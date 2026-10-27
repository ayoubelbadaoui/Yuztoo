import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/config/vitrine_qr_config.dart';
import 'package:flutter_yuztoo/core/infrastructure/tolerant_mapping.dart';
import 'package:flutter_yuztoo/feature/client_notification/infrastructure/dto/client_notification_dto.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/client_gratification_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant_storefront_link.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/dto/merchant_dto.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/loyalty_program_firestore_mapper.dart';
import 'package:flutter_yuztoo/feature/merchant_partners/infrastructure/dto/merchant_partner_dto.dart';
import 'package:flutter_yuztoo/feature/promotions/infrastructure/dto/promotion_dto.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/dto/auto_notification_dto.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/dto/sent_notification_dto.dart';
import 'package:flutter_yuztoo/feature/storefront/domain/entities/business_hours.dart';

/// Hostile-input fuzzing: data that no manual tester would ever type.
///
/// QR codes, NFC tags, BLE payloads and Firestore documents edited from the
/// console or by older app versions can hold any shape. Every parser fed
/// by them must return a value (or null) — never throw.
void main() {
  const iterations = 3000;

  Object? randomValue(Random r, {int depth = 0}) {
    switch (r.nextInt(depth > 2 ? 12 : 14)) {
      case 0:
        return null;
      case 1:
        return r.nextBool();
      case 2:
        return r.nextInt(1 << 31) - (1 << 30);
      case 3:
        return [
          double.nan,
          double.infinity,
          double.negativeInfinity,
          -0.0,
          1e308,
          -1e-308,
          0.5
        ][r.nextInt(7)];
      case 4:
        return '';
      case 5:
        return ' ' * r.nextInt(5);
      case 6:
        return String.fromCharCodes(
            List.generate(r.nextInt(40), (_) => r.nextInt(0xFFFF)));
      case 7:
        return 'x' * (r.nextInt(3) == 0 ? 20000 : r.nextInt(30));
      case 8:
        return [
          'true',
          'false',
          '0',
          '1',
          'null',
          'NaN',
          '-1',
          '12:00',
          '25:99',
          'visit_count',
          'manual',
          '../..',
          '__x__'
        ][r.nextInt(13)];
      case 9:
        return Timestamp.fromMillisecondsSinceEpoch(r.nextInt(1 << 31) * 1000);
      case 10:
        return r.nextInt(1000).toDouble() / 7;
      case 11:
        return 'https://yuztoo.web.app/vitrine/${r.nextInt(99999)}';
      case 12:
        return List.generate(
            r.nextInt(5), (_) => randomValue(r, depth: depth + 1));
      default:
        return {
          for (var i = 0; i < r.nextInt(5); i++)
            [
              'open',
              'close',
              'start',
              'end',
              'label',
              'value',
              'slots',
              'closed',
              'enabled',
              'x'
            ][r.nextInt(10)]: randomValue(r, depth: depth + 1),
        };
    }
  }

  /// Field names actually read by a parser, extracted from its source so the
  /// fuzzer hits real code paths instead of random keys.
  Set<String> keysReadIn(String path) {
    final src = File(path).readAsStringSync();
    return RegExp(r"""\[\s*'([a-zA-Z0-9_]+)'\s*\]""")
        .allMatches(src)
        .map((m) => m.group(1)!)
        .toSet();
  }

  Map<String, dynamic> randomDoc(Random r, Set<String> keys) => {
        for (final k in keys)
          if (r.nextInt(4) != 0) k: randomValue(r),
      };

  group('Scanned payloads (QR / NFC / deep links)', () {
    test('tryParseMerchantId never throws and only returns safe ids', () {
      final r = Random(1);
      final samples = <String>[
        'https://yuztoo.web.app/vitrine/abc%2F..%2Fusers',
        'https://yuztoo.web.app/vitrine/..',
        'https://yuztoo.web.app/vitrine/__name__',
        'https://yuztoo.web.app/vitrine/${'a' * 5000}',
        'yuztoo://vitrine/%00',
        'yuztoo://vitrine/',
        'https://yuztoo.web.app/vitrine',
        'http://[::1',
        '%',
        'https://evil.com/vitrine/abc',
        for (var i = 0; i < iterations; i++) (randomValue(r) ?? '').toString(),
        for (var i = 0; i < iterations; i++)
          'https://yuztoo.web.app/vitrine/${randomValue(r)}',
      ];
      for (final s in samples) {
        final id = VitrineQrConfig.tryParseMerchantId(s);
        if (id != null) {
          expect(VitrineQrConfig.isValidMerchantId(id), isTrue, reason: s);
        }
      }
      expect(
        VitrineQrConfig.tryParseMerchantId(
            'https://yuztoo.web.app/vitrine/5HcmoOv9U2QPojMUpGeEsc7nbQt2'),
        '5HcmoOv9U2QPojMUpGeEsc7nbQt2',
      );
    });
  });

  group('Map parsers never throw on hostile maps', () {
    void fuzzMap(
        String name, String source, void Function(Map<String, dynamic>) parse) {
      test(name, () {
        final r = Random(name.hashCode);
        final keys = keysReadIn(source);
        for (var i = 0; i < iterations; i++) {
          final doc = randomDoc(r, keys);
          try {
            parse(doc);
          } catch (e) {
            fail('$name threw ${e.runtimeType}: $e\ninput: $doc');
          }
        }
      });
    }

    fuzzMap(
      'LoyaltyProgramFirestoreMapper.fromFirestoreMap',
      'lib/feature/merchant/infrastructure/loyalty_program_firestore_mapper.dart',
      LoyaltyProgramFirestoreMapper.fromFirestoreMap,
    );
    fuzzMap(
      'ClientGratificationConfig.fromMap',
      'lib/feature/merchant/domain/entities/client_gratification_config.dart',
      ClientGratificationConfig.fromMap,
    );
    fuzzMap(
      'MerchantStorefrontLink.fromMap',
      'lib/feature/merchant/domain/entities/merchant_storefront_link.dart',
      MerchantStorefrontLink.fromMap,
    );
    fuzzMap(
      'ActiveValidationRequest.fromFirestoreMap',
      'lib/feature/loyalty/domain/entities/active_validation_request.dart',
      (m) => ActiveValidationRequest.fromFirestoreMap(
        merchantId: 'm1',
        clientUid: 'c1',
        data: m,
      ),
    );
    fuzzMap(
      'BusinessHours.fromMap',
      'lib/feature/storefront/domain/entities/business_hours.dart',
      (m) {
        final r = Random(m.length);
        BusinessHours.fromMap({
          for (final day in BusinessHours.dayKeys) day: randomValue(r),
          ...m,
        });
      },
    );
  });

  group('Firestore DTOs survive hostile documents', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    Future<void> fuzzDoc(
      String name,
      String source,
      Object? Function(DocumentSnapshot<Map<String, dynamic>> doc) parse,
    ) async {
      final r = Random(name.hashCode);
      final keys = keysReadIn(source);
      final failures = <String>{};
      final docs = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (var i = 0; i < 400; i++) {
        final ref = db.collection('fuzz_$name').doc('d$i');
        await ref.set(randomDoc(r, keys));
        docs.add(await ref.get());
      }
      for (final d in docs) {
        try {
          parse(d);
        } catch (e) {
          failures.add(e.toString().split('\n').first);
        }
      }
      // The list-level guard must hold no matter what individual docs do.
      expect(() => docs.mapSkippingInvalid(parse), returnsNormally);
      expect(failures, isEmpty,
          reason:
              '$name threw on hostile docs:\n${failures.take(5).join('\n')}');
    }

    test(
        'MerchantDto',
        () => fuzzDoc(
              'merchant',
              'lib/feature/merchant/infrastructure/dto/merchant_dto.dart',
              (d) => MerchantDto.fromFirestore(d).toDomain(),
            ));
    test(
        'ClientNotificationDto',
        () => fuzzDoc(
              'notification',
              'lib/feature/client_notification/infrastructure/dto/client_notification_dto.dart',
              (d) => ClientNotificationDto.fromFirestore(d, 'c1').toDomain(),
            ));
    test(
        'PromotionDto',
        () => fuzzDoc(
              'promotion',
              'lib/feature/promotions/infrastructure/dto/promotion_dto.dart',
              (d) => PromotionDto.fromFirestore(d, 'm1')?.toDomain(),
            ));
    test(
        'AutoNotificationDto',
        () => fuzzDoc(
              'auto_notification',
              'lib/feature/rappels/infrastructure/dto/auto_notification_dto.dart',
              (d) => AutoNotificationDto.fromFirestore(d, 'm1').toDomain(),
            ));
    test(
        'SentNotificationDto',
        () => fuzzDoc(
              'sent_notification',
              'lib/feature/rappels/infrastructure/dto/sent_notification_dto.dart',
              (d) => SentNotificationDto.fromFirestore(d).toDomain(),
            ));
    test(
        'MerchantPartnerDto',
        () => fuzzDoc(
              'partner',
              'lib/feature/merchant_partners/infrastructure/dto/merchant_partner_dto.dart',
              (d) => MerchantPartnerDto.fromFirestore(d, 'm1')?.toDomain(),
            ));
  });

  test('mapSkippingInvalid keeps good items and drops bad ones', () {
    final out = [1, 0, 2].mapSkippingInvalid((n) => 10 ~/ n);
    expect(out, [10, 5]);
  });
}
