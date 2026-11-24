import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';

import 'package:flutter_yuztoo/feature/auth/core/infrastructure/firebase_user_repository.dart';

void main() {
  const uid = 'client-onboard-1';

  late FakeFirebaseFirestore firestore;
  late FirebaseUserRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirebaseUserRepository(firestore: firestore);
  });

  Future<void> seedClientDoc() async {
    await firestore.collection('users').doc(uid).set(<String, dynamic>{
      'uid': uid,
      'email': 'client@example.com',
      'roles': <String, bool>{
        'client': true,
        'merchant': false,
        'provider': false,
      },
      'primary_role': 'client',
      'merchant_id': null,
      'onboarding': <String, String>{
        'merchant': 'not_started',
        'client': 'not_started',
      },
      'status': 'active',
    });
  }

  test(
      'completeClientProfile marks onboarding.client completed and keeps merchant not_started',
      () async {
    await seedClientDoc();

    final result = await repo.completeClientProfile(
      uid: uid,
      displayName: 'Julie Test',
      firstName: 'Julie',
      lastName: 'Test',
      city: null,
      photoUrl: null,
      dateOfBirth: null,
    );

    expect(result.isRight, isTrue,
        reason: result.fold((f) => f.message, (_) => ''));

    final data = (await firestore.collection('users').doc(uid).get()).data()!;
    final onboarding = Map<String, dynamic>.from(data['onboarding'] as Map);
    expect(onboarding['client'], 'completed');
    expect(onboarding['merchant'], 'not_started');
    expect(data['first_name'], 'Julie');
    expect(data['last_name'], 'Test');
    expect(data['displayName'], 'Julie Test');
    expect(data.containsKey('city'), isFalse);
  });

  test(
      'completeClientProfile defaults missing merchant key to not_started not completed',
      () async {
    await firestore.collection('users').doc(uid).set(<String, dynamic>{
      'uid': uid,
      'email': 'client@example.com',
      'roles': <String, bool>{
        'client': true,
        'merchant': false,
        'provider': false,
      },
      'primary_role': 'client',
      'status': 'active',
      // Partial onboarding map — merchant key absent (legacy / broken writes).
      'onboarding': <String, String>{'client': 'not_started'},
    });

    final result = await repo.completeClientProfile(
      uid: uid,
      displayName: 'Benji Test',
      firstName: 'Benji',
      lastName: 'Test',
    );
    expect(result.isRight, isTrue);

    final data = (await firestore.collection('users').doc(uid).get()).data()!;
    final onboarding = Map<String, dynamic>.from(data['onboarding'] as Map);
    expect(
      onboarding['merchant'],
      'not_started',
      reason:
          'putIfAbsent must default merchant to not_started, never completed',
    );
    expect(onboarding['client'], 'completed');
  });

  test('completeClientProfile keeps city and writes official metadata',
      () async {
    await seedClientDoc();

    final result = await repo.completeClientProfile(
      uid: uid,
      displayName: 'Julie Test',
      city: 'Saint-Denis',
      commune: const FrenchCommune(
        name: 'Saint-Denis',
        inseeCode: '93066',
        postalCodes: ['93200'],
        population: 149077,
        departmentCode: '93',
        epciCode: '200054781',
      ),
    );

    expect(result.isRight, isTrue);
    final data = (await firestore.collection('users').doc(uid).get()).data()!;
    expect(data['city'], 'Saint-Denis');
    final metadata = Map<String, dynamic>.from(data['city_metadata'] as Map);
    expect(metadata['insee_code'], '93066');
    expect(metadata['size'], 'largeCity');
    expect(metadata['epci_code'], '200054781');
    expect(metadata['source'], 'geo.api.gouv.fr');
  });

  test('isClientOnboardingCompleted is false until completeClientProfile',
      () async {
    await seedClientDoc();

    final before = await repo.isClientOnboardingCompleted(uid);
    expect(before.isRight, isTrue);
    before.fold((_) => fail('expected Right'), (v) => expect(v, isFalse));

    await repo.completeClientProfile(
      uid: uid,
      displayName: 'A B',
      firstName: 'A',
      lastName: 'B',
    );

    final after = await repo.isClientOnboardingCompleted(uid);
    after.fold((_) => fail('expected Right'), (v) => expect(v, isTrue));
  });
}
