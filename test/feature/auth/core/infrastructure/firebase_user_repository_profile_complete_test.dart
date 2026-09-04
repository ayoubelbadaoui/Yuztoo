import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/infrastructure/firebase_user_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// checkUserProfileComplete — Firestore-backed
//
// Guards the client login path: `LoginFlowController.signIn` turns a `false`
// here into `ProfileIncompleteFailure`, which only shows a "Profil incomplet"
// snackbar and leaves the user stuck on the login screen with no recovery.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const uid = 'c1';

  late FakeFirebaseFirestore firestore;
  late FirebaseUserRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirebaseUserRepository(firestore: firestore);
  });

  Future<void> seedEmailSignupDoc() async {
    // Exactly what `createUserDocument` writes for an email signup: no
    // `phone` key, since phone collection was dropped from that flow.
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

  test('email signup client (no phone field) can log in', () async {
    await seedEmailSignupDoc();
    final result = await repo.checkUserProfileComplete(uid);
    expect(result.isRight, isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (complete) => expect(
        complete,
        isTrue,
        reason: 'a phone-less account must not be rejected at login',
      ),
    );
  });

  test('missing user document reports incomplete', () async {
    final result = await repo.checkUserProfileComplete(uid);
    expect(result.isRight, isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (complete) => expect(complete, isFalse),
    );
  });

  test('document missing status reports incomplete', () async {
    await seedEmailSignupDoc();
    await firestore.collection('users').doc(uid).update(<String, dynamic>{
      'status': '',
    });
    final result = await repo.checkUserProfileComplete(uid);
    result.fold(
      (_) => fail('expected Right'),
      (complete) => expect(complete, isFalse),
    );
  });
}
