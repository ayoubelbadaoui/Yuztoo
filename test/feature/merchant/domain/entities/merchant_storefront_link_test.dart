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
      expect(MerchantStorefrontLink.looksLikeUrl('Parking gratuit'), isFalse);
      expect(MerchantStorefrontLink.looksLikeUrl('PDF'), isFalse);
      expect(MerchantStorefrontLink.looksLikeUrl('https://'), isFalse);
    });

    group('shortUrl', () {
      String short(String raw) => MerchantStorefrontLink.shortUrl(raw);

      test('drops scheme, www, query and trailing slash', () {
        expect(short('https://www.instagram.com/lebistro/?hl=fr'),
            'instagram.com/lebistro');
        expect(short('https://www.example.fr/'), 'example.fr');
        expect(short('book.example'), 'book.example');
      });

      test('long path keeps only the host', () {
        expect(
          short('https://www.thefork.fr/restaurant/le-bistro-de-belfort-r123456'
              '?utm_source=google'),
          'thefork.fr',
        );
      });

      test('single handle is kept, deeper or long paths are dropped', () {
        expect(short('https://www.tiktok.com/@lebistro'),
            'tiktok.com/@lebistro');
        expect(short('https://facebook.com/lebistro/photos/123'),
            'facebook.com');
        expect(short('https://linktr.ee/le-bistro-de-la-place-belfort'),
            'linktr.ee');
      });

      test('host is lower-cased', () {
        expect(short('HTTPS://WWW.Example.COM'), 'example.com');
      });
    });

    test('displayValue shortens URLs but keeps free text', () {
      const url = MerchantStorefrontLink(
        label: 'Réserver',
        value: 'https://www.zenchef.com/reservation/le-bistro-belfort-1234',
      );
      const text = MerchantStorefrontLink(
        label: 'Parking',
        value: 'Gratuit derrière la boutique, entrée rue Thiers',
      );
      expect(url.displayValue, 'zenchef.com');
      expect(url.launchUri.toString(), url.value);
      expect(text.displayValue, text.value);
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
