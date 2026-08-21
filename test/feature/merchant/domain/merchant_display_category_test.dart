import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

Merchant _m({
  List<String>? categories,
  String? subcategoryTitle,
  String city = 'Paris',
}) =>
    Merchant(
      id: 'm1',
      ownerUid: 'o1',
      name: 'Shop',
      email: 's@test.com',
      phone: '+33600000000',
      city: city,
      categories: categories,
      subcategoryTitle: subcategoryTitle,
    );

void main() {
  group('Merchant.displayCategory', () {
    test('prefers subcategory over categories', () {
      final m = _m(
        categories: const ['Boutique'],
        subcategoryTitle: 'Boulangerie',
      );
      expect(m.displayCategory, 'Boulangerie');
    });

    test('filters corrupted legacy Artisan Jewelry from subcategory', () {
      final m = _m(
        categories: const ['Boutique'],
        subcategoryTitle: 'Artisan Jewelry',
      );
      expect(m.displayCategory, 'Boutique');
    });

    test('filters corrupted legacy from categories list', () {
      final m = _m(categories: const ['Artisan Jewelry']);
      expect(m.displayCategory, isNull);
    });

    test('returns null when nothing displayable', () {
      expect(_m().displayCategory, isNull);
    });

    test('skips empty / whitespace subcategory', () {
      final m = _m(categories: const ['Café'], subcategoryTitle: '  ');
      expect(m.displayCategory, 'Café');
    });
  });
}
