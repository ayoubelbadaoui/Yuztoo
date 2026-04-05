import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/utils/city_input.dart';

void main() {
  test('isPlaceholder treats À compléter and empty as non-persistable', () {
    expect(CityInput.isPlaceholder('À compléter'), true);
    expect(CityInput.isPlaceholder('À COMPLÉTER'), true);
    expect(CityInput.isPlaceholder('  Votre ville '), true);
    expect(CityInput.isPlaceholder('Paris'), false);
  });

  test('forEditField never shows À compléter as the real city', () {
    expect(CityInput.forEditField('À compléter'), 'Votre ville');
    expect(CityInput.forEditField('Lyon'), 'Lyon');
  });
}
