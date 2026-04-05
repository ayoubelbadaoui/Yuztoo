import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/merchant_city_resolution.dart';

void main() {
  group('resolveMerchantCityForCreation', () {
    test('uses signup city when onboarding sends À compléter', () {
      expect(
        resolveMerchantCityForCreation(
          incomingMerchantCity: 'À compléter',
          signupCityFromUserDoc: 'Paris',
        ),
        'Paris',
      );
    });

    test('uses signup city when onboarding sends Votre ville', () {
      expect(
        resolveMerchantCityForCreation(
          incomingMerchantCity: 'Votre ville',
          signupCityFromUserDoc: 'Lyon',
        ),
        'Lyon',
      );
    });

    test('uses signup city when onboarding sends empty string', () {
      expect(
        resolveMerchantCityForCreation(
          incomingMerchantCity: '',
          signupCityFromUserDoc: 'Nice',
        ),
        'Nice',
      );
    });

    test('keeps onboarding city when it is a real city (ignores signup)', () {
      expect(
        resolveMerchantCityForCreation(
          incomingMerchantCity: 'Marseille',
          signupCityFromUserDoc: 'Paris',
        ),
        'Marseille',
      );
    });

    test('keeps placeholder when signup has no city', () {
      expect(
        resolveMerchantCityForCreation(
          incomingMerchantCity: 'À compléter',
          signupCityFromUserDoc: '',
        ),
        'À compléter',
      );
    });

    test('trims whitespace on preserved onboarding city', () {
      expect(
        resolveMerchantCityForCreation(
          incomingMerchantCity: '  Bordeaux  ',
          signupCityFromUserDoc: 'Paris',
        ),
        'Bordeaux',
      );
    });
  });
}
