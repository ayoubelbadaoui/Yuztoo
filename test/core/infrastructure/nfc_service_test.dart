import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/config/vitrine_qr_config.dart';
import 'package:flutter_yuztoo/core/infrastructure/nfc_service.dart';
import 'package:flutter_yuztoo/core/infrastructure/nfc_vitrine_poll_config.dart';
import 'package:ndef/ndef.dart' as ndef;

import 'fakes/nfc_method_channel_fake.dart';

void main() {
  late NfcMethodChannelFake fake;

  void enableMobile({required bool ios}) {
    NfcService.debugForceMobileNfcSupported = true;
    NfcService.debugSimulateIos = ios;
  }

  void resetMobile() {
    NfcService.debugForceMobileNfcSupported = null;
    NfcService.debugSimulateIos = null;
  }

  setUp(() {
    fake = NfcMethodChannelFake()..install();
  });

  tearDown(() {
    fake.dispose();
    resetMobile();
  });

  group('NfcVitrinePollConfig', () {
    test('iOS polls ISO 14443 only (no FeliCa / ISO15693 entitlements)', () {
      expect(
        NfcVitrinePollConfig.technologyBitmask(isIos: true),
        NfcVitrinePollConfig.iso14443Mask,
      );
      expect(
        NfcVitrinePollConfig.technologyBitmask(isIos: true) & 0xC,
        0,
      );
    });

    test('Android polls ISO 14443 + FeliCa + ISO15693', () {
      expect(
        NfcVitrinePollConfig.technologyBitmask(isIos: false),
        NfcVitrinePollConfig.iso14443Mask |
            NfcVitrinePollConfig.iso18092Mask |
            NfcVitrinePollConfig.iso15693Mask,
      );
    });
  });

  group('NfcService availability', () {
    test('desktop test host reports unsupported without debug override', () {
      expect(NfcService.isSupported, isFalse);
    });

    test('unavailableReason when NFC disabled in OS settings', () async {
      enableMobile(ios: true);
      fake.availability = 'disabled';
      expect(
        await NfcService.unavailableReason(),
        contains('réglages'),
      );
      expect(await NfcService.isAvailable(), isFalse);
    });

    test('unavailableReason when hardware lacks NFC', () async {
      enableMobile(ios: false);
      fake.availability = 'not_supported';
      expect(
        await NfcService.unavailableReason(),
        'NFC non disponible sur cet appareil.',
      );
    });

    test('isAvailable when reader is ready', () async {
      enableMobile(ios: true);
      fake.availability = 'available';
      expect(await NfcService.unavailableReason(), isNull);
      expect(await NfcService.isAvailable(), isTrue);
    });
  });

  group('NfcService.readVitrineMerchantId', () {
    test('reads HTTPS vitrine URI from NTAG213', () async {
      enableMobile(ios: true);
      const merchantId = 'shop_paris_01';
      final url = VitrineQrConfig.uriStringForMerchant(merchantId);
      fake.readRecords = [ndef.UriRecord.fromString(url)];

      final result = await NfcService.readVitrineMerchantId();

      expect(result, isA<NfcSuccess>());
      expect((result as NfcSuccess).merchantId, merchantId);
      expect(fake.calls, contains('poll'));
      expect(fake.calls, contains('readNDEF'));
      expect(fake.lastFinishSuccessMessage, 'Tag lu !');
      expect(
        fake.lastPollTechnologies,
        NfcVitrinePollConfig.technologyBitmask(isIos: true),
      );
    });

    test('reads vitrine URL from raw UTF-8 NDEF payload fallback', () async {
      enableMobile(ios: false);
      const merchantId = 'raw_payload_shop';
      final url = VitrineQrConfig.uriStringForMerchant(merchantId);
      fake.readRecords = [
        ndef.MimeRecord(
          decodedType: 'text/plain',
          payload: utf8.encode(url),
        ),
      ];

      final result = await NfcService.readVitrineMerchantId();

      expect(result, isA<NfcSuccess>());
      expect((result as NfcSuccess).merchantId, merchantId);
      expect(
        fake.lastPollTechnologies,
        NfcVitrinePollConfig.technologyBitmask(isIos: false),
      );
    });

    test('empty NDEF message returns French empty-badge copy', () async {
      enableMobile(ios: true);
      fake.readRecords = const [];

      final result = await NfcService.readVitrineMerchantId();

      expect(result, isA<NfcError>());
      expect(
        (result as NfcError).message,
        contains('badge NFC est vide'),
      );
      expect(fake.lastFinishErrorMessage, 'Badge vide.');
    });

    test('non-Yuztoo URL returns invalid vitrine message', () async {
      enableMobile(ios: true);
      fake.readRecords = [ndef.UriRecord.fromString('https://example.com/x')];

      final result = await NfcService.readVitrineMerchantId();

      expect((result as NfcError).message, contains('vitrine Yuztoo'));
      expect(fake.lastFinishErrorMessage, 'Badge non Yuztoo.');
    });

    test('user cancel returns Lecture annulée without error snack noise', () async {
      enableMobile(ios: true);
      fake.pollError = PlatformException(
        code: '409',
        message: 'SessionCanceled',
      );

      final result = await NfcService.readVitrineMerchantId();

      expect(result, isA<NfcError>());
      expect((result as NfcError).message, 'Lecture annulée.');
    });

    test('iOS missing entitlement maps to reinstall guidance', () async {
      enableMobile(ios: true);
      fake.pollError = PlatformException(
        code: '500',
        message: 'Generic NFC Error',
        details: 'Missing required entitlement',
      );

      final result = await NfcService.readVitrineMerchantId();

      expect((result as NfcError).message, contains('TestFlight'));
    });

    test('active session conflict maps to retry message', () async {
      enableMobile(ios: false);
      fake.pollError = PlatformException(
        code: '406',
        message: 'Cannot invoke poll in a active session',
      );

      final result = await NfcService.readVitrineMerchantId();

      expect((result as NfcError).message, contains('déjà en cours'));
    });

    test('blocked when NFC disabled before poll starts', () async {
      enableMobile(ios: true);
      fake.availability = 'disabled';

      final result = await NfcService.readVitrineMerchantId();

      expect(result, isA<NfcError>());
      expect(fake.calls, isNot(contains('poll')));
    });
  });

  group('NfcService.writeVitrineUrl', () {
    test('writes same URL as merchant QR code (round-trip)', () async {
      enableMobile(ios: true);
      const merchantId = 'merchant_roundtrip';
      fake.pollTag = NfcMethodChannelFake.tagWith(
        ndefAvailable: true,
        ndefWritable: true,
        ndefCapacity: 137,
      );

      final result = await NfcService.writeVitrineUrl(merchantId);

      expect(result, isA<NfcSuccess>());
      expect(fake.calls, contains('writeNDEF'));
      expect(fake.lastFinishSuccessMessage, 'Badge programmé !');

      final written = fake.decodeLastWrittenUriRecord();
      expect(written, isA<ndef.UriRecord>());
      final url = (written as ndef.UriRecord).uri?.toString();
      expect(url, VitrineQrConfig.uriStringForMerchant(merchantId));
      expect(
        VitrineQrConfig.tryParseMerchantId(url ?? ''),
        merchantId,
      );
    });

    test('rejects empty merchant id before polling', () async {
      enableMobile(ios: false);

      final result = await NfcService.writeVitrineUrl('   ');

      expect(result, isA<NfcError>());
      expect((result as NfcError).message, contains('Identifiant commerce'));
      expect(fake.calls, isNot(contains('poll')));
    });

    test('rejects non-NDEF sticker before write', () async {
      enableMobile(ios: true);
      fake.pollTag = NfcMethodChannelFake.tagWith(ndefAvailable: false);

      final result = await NfcService.writeVitrineUrl('shop1');

      expect((result as NfcError).message, contains('compatible NDEF'));
      expect(fake.calls, isNot(contains('writeNDEF')));
      expect(fake.lastFinishErrorMessage, 'Badge non NDEF.');
    });

    test('rejects read-only NTAG213', () async {
      enableMobile(ios: false);
      fake.pollTag = NfcMethodChannelFake.tagWith(ndefWritable: false);

      final result = await NfcService.writeVitrineUrl('shop1');

      expect((result as NfcError).message, contains('lecture seule'));
      expect(fake.lastFinishErrorMessage, 'Badge en lecture seule.');
    });

    test('rejects URL larger than NTAG213 NDEF capacity', () async {
      enableMobile(ios: true);
      final longId = 'm' * 120;
      fake.pollTag = NfcMethodChannelFake.tagWith(ndefCapacity: 40);

      final result = await NfcService.writeVitrineUrl(longId);

      expect((result as NfcError).message, contains('Capacité du badge'));
      expect(fake.calls, isNot(contains('writeNDEF')));
    });

    test('user cancel returns Programmation annulée', () async {
      enableMobile(ios: true);
      fake.pollError = PlatformException(
        code: '409',
        message: 'SessionCanceled',
      );

      final result = await NfcService.writeVitrineUrl('shop1');

      expect((result as NfcError).message, 'Programmation annulée.');
    });

    test('platform readonly error surfaces French copy', () async {
      enableMobile(ios: false);
      fake.pollTag = NfcMethodChannelFake.tagWith();
      fake.writeError = PlatformException(
        code: '500',
        message: 'Write NDEF error',
        details: 'Tag is readonly',
      );

      final result = await NfcService.writeVitrineUrl('shop1');

      expect((result as NfcError).message, contains('lecture seule'));
    });
  });

  group('NfcService.cancelActiveSession', () {
    test('invokes finish on mobile platforms', () async {
      enableMobile(ios: true);

      await NfcService.cancelActiveSession();

      expect(fake.calls, contains('finish'));
    });

    test('no-op on unsupported desktop host', () async {
      resetMobile();

      await NfcService.cancelActiveSession();

      expect(fake.calls, isEmpty);
    });
  });

  group('NFC vitrine URL matrix (QR parity)', () {
    const cases = <({String id, String? expected})>[
      (id: 'abc123', expected: 'abc123'),
      (id: ' merchant_spaces ', expected: 'merchant_spaces'),
      (id: '', expected: null),
      (id: '   ', expected: null),
    ];

    for (final c in cases) {
      test('parse/write parity for "${c.id}"', () {
        final url = VitrineQrConfig.uriStringForMerchant(c.id);
        if (c.expected == null) {
          expect(url, isEmpty);
        } else {
          expect(url, 'https://yuztoo.web.app/vitrine/${c.id.trim()}');
          expect(VitrineQrConfig.tryParseMerchantId(url), c.expected);
        }
      });
    }

    test('custom scheme yuztoo://vitrine/{id}', () {
      expect(
        VitrineQrConfig.tryParseMerchantId('yuztoo://vitrine/my-shop'),
        'my-shop',
      );
    });

    test('rejects third-party NFC payloads', () {
      expect(
        VitrineQrConfig.tryParseMerchantId('https://example.com/vitrine/x'),
        isNull,
      );
    });

    test('NDEF URI record fits NTAG213 for typical Firestore ids', () {
      const merchantId = 'kR7xFirebaseStyleMerchantId99';
      final record = ndef.UriRecord.fromString(
        VitrineQrConfig.uriStringForMerchant(merchantId),
      );
      expect(record.encode().length, lessThan(137));
    });
  });
}
