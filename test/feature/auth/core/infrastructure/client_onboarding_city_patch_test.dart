import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/client_onboarding_city_patch.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/firebase_user_repository.dart';

const _hericourt = FrenchCommune(
  name: 'Héricourt',
  inseeCode: '70285',
  departmentCode: '70',
  epciCode: '247000623',
);

void main() {
  group('clientOnboardingCityPatch', () {
    test('no list yet (normal client): only city + city_metadata', () {
      final p = clientOnboardingCityPatch(
        existingUserData: {'city': null},
        city: 'Héricourt',
        commune: _hericourt,
      );
      expect(p.keys, unorderedEquals(['city', 'city_metadata']));
      expect(p['city'], 'Héricourt');
    });

    test('merchant creating a client account: picked city goes first, shop '
        'city kept', () {
      final p = clientOnboardingCityPatch(
        existingUserData: {
          'city': 'Montbéliard',
          'cities': ['Montbéliard'],
          'cities_metadata': {
            'Montbéliard': {'name': 'Montbéliard', 'epci_code': '200065647'},
          },
        },
        city: 'Héricourt',
        commune: _hericourt,
      );
      expect(p['cities'], ['Héricourt', 'Montbéliard']);
      final meta = p['cities_metadata'] as Map;
      expect(meta.keys, unorderedEquals(['Héricourt', 'Montbéliard']));
      expect(meta['Héricourt']['epci_code'], '247000623');
    });

    test('same city with other accents / case is not duplicated', () {
      final p = clientOnboardingCityPatch(
        existingUserData: {
          'cities': ['HERICOURT', 'Belfort'],
          'cities_metadata': {'HERICOURT': {'name': 'Héricourt'}},
        },
        city: 'Héricourt',
        commune: _hericourt,
      );
      expect(p['cities'], ['Héricourt', 'Belfort']);
      expect((p['cities_metadata'] as Map).keys, ['Héricourt']);
    });

    test('no city chosen (step skipped): nothing written', () {
      expect(
        clientOnboardingCityPatch(
            existingUserData: {'cities': ['Belfort']}, city: null),
        isEmpty,
      );
      expect(
        clientOnboardingCityPatch(existingUserData: null, city: '   '),
        isEmpty,
      );
    });
  });

  test('completeClientProfile: Découvrir (getConnectedCities) now sees the '
      'city picked in onboarding for a dual-profile user', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirebaseUserRepository(firestore: db);
    await db.collection('users').doc('u1').set({
      'uid': 'u1',
      'roles': {'client': true, 'merchant': true, 'provider': true},
      'primary_role': 'merchant',
      'onboarding': {'merchant': 'completed', 'client': 'not_started'},
      'status': 'active',
      'city': 'Montbéliard',
      'cities': ['Montbéliard'],
    });

    final result = await repo.completeClientProfile(
      uid: 'u1',
      displayName: 'Sara Test',
      city: 'Héricourt',
      commune: _hericourt,
    );
    expect(result.isRight, isTrue);

    final cities = await repo.getConnectedCities('u1');
    expect(cities.rightOrNull, ['Héricourt', 'Montbéliard'],
        reason: 'before the fix this was [Montbéliard] only');
    final meta = await repo.getConnectedCitiesMetadata('u1');
    expect(meta.rightOrNull?['Héricourt']?.epciCode, '247000623');
  });
}
