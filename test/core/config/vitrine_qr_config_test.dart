import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/config/vitrine_qr_config.dart';

void main() {
  group('VitrineQrConfig.uriStringForMerchant', () {
    test('builds canonical https QR URL', () {
      expect(
        VitrineQrConfig.uriStringForMerchant('abc123'),
        'https://yuztoo.web.app/vitrine/abc123',
      );
    });

    test('trims and rejects empty', () {
      expect(VitrineQrConfig.uriStringForMerchant('  '), '');
      expect(VitrineQrConfig.uriStringForMerchant(' mid '), 'https://yuztoo.web.app/vitrine/mid');
    });
  });

  group('VitrineQrConfig.tryParseMerchantId', () {
    test('parses https vitrine path', () {
      expect(
        VitrineQrConfig.tryParseMerchantId(
          'https://yuztoo.web.app/vitrine/Merch_01-xyz',
        ),
        'Merch_01-xyz',
      );
    });

    test('parses custom scheme', () {
      expect(
        VitrineQrConfig.tryParseMerchantId('yuztoo://vitrine/shop99'),
        'shop99',
      );
    });

    test('rejects invalid ids', () {
      expect(
        VitrineQrConfig.tryParseMerchantId('https://yuztoo.web.app/vitrine/../x'),
        isNull,
      );
      expect(
        VitrineQrConfig.tryParseMerchantId('https://evil.com/vitrine/abc'),
        isNull,
      );
    });
  });

  group('VitrineQrConfig.tryParseMerchantIdFromInstallReferrer', () {
    test('parses vitrine= referrer from Play Store', () {
      expect(
        VitrineQrConfig.tryParseMerchantIdFromInstallReferrer('vitrine=abcXYZ_1'),
        'abcXYZ_1',
      );
    });

    test('parses percent-encoded referrer', () {
      expect(
        VitrineQrConfig.tryParseMerchantIdFromInstallReferrer(
          'vitrine%3Dshop42',
        ),
        'shop42',
      );
    });

    test('parses utm_content fallback', () {
      expect(
        VitrineQrConfig.tryParseMerchantIdFromInstallReferrer(
          'utm_source=qr&utm_content=cafe99',
        ),
        'cafe99',
      );
    });

    test('parses full https URL inside referrer', () {
      expect(
        VitrineQrConfig.tryParseMerchantIdFromInstallReferrer(
          'https://yuztoo.web.app/vitrine/fullLink1',
        ),
        'fullLink1',
      );
    });

    test('returns null for empty or junk', () {
      expect(VitrineQrConfig.tryParseMerchantIdFromInstallReferrer(null), isNull);
      expect(VitrineQrConfig.tryParseMerchantIdFromInstallReferrer(''), isNull);
      expect(
        VitrineQrConfig.tryParseMerchantIdFromInstallReferrer('utm_source=organic'),
        isNull,
      );
      expect(
        VitrineQrConfig.tryParseMerchantIdFromInstallReferrer('vitrine=bad/id'),
        isNull,
      );
    });
  });
}
