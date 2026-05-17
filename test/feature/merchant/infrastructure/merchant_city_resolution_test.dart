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

    test('returns empty when signup has no usable city', () {
      expect(
        resolveMerchantCityForCreation(
          incomingMerchantCity: 'À compléter',
          signupCityFromUserDoc: '',
        ),
        '',
      );
    });

    test('returns empty when both sides are placeholders', () {
      expect(
        resolveMerchantCityForCreation(
          incomingMerchantCity: 'Votre ville',
          signupCityFromUserDoc: 'À compléter',
        ),
        '',
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

  group('mergedOwnerConnectedCities', () {
    test('adds merchant city to existing cities list', () {
      expect(
        mergedOwnerConnectedCities(
          existingUserData: {
            'cities': ['Paris'],
            'city': 'Paris',
          },
          persistedCity: 'Lyon',
        ),
        containsAll(['Paris', 'Lyon']),
      );
    });

    test('dedupes case-sensitive entries as separate (display names)', () {
      final list = mergedOwnerConnectedCities(
        existingUserData: const {'cities': ['Lyon']},
        persistedCity: 'Lyon',
      );
      expect(list, ['Lyon']);
    });
  });
}
