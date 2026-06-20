import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant_storefront_link.dart';

void main() {
  group('MerchantStorefrontLink', () {
    test('looksLikeUrl accepts http and https', () {
      expect(MerchantStorefrontLink.looksLikeUrl('https://book.example'), isTrue);
      expect(MerchantStorefrontLink.looksLikeUrl('http://book.example'), isTrue);
      expect(MerchantStorefrontLink.looksLikeUrl('book.example'), isTrue);
      expect(MerchantStorefrontLink.looksLikeUrl('tel:+33123456789'), isFalse);
      expect(MerchantStorefrontLink.looksLikeUrl(''), isFalse);
    });

    test('fromMap and toMap round-trip', () {
      const link = MerchantStorefrontLink(
        label: ' Réservation ',
        value: ' https://book.example ',
      );
      final parsed = MerchantStorefrontLink.fromMap(link.toMap());
      expect(parsed.label, 'Réservation');
      expect(parsed.value, 'https://book.example');
    });

    test('isValid requires both fields', () {
      expect(
        const MerchantStorefrontLink(label: 'Menu', value: 'PDF').isValid,
        isTrue,
      );
      expect(
        const MerchantStorefrontLink(label: '', value: 'x').isValid,
        isFalse,
      );
    });
  });
}
