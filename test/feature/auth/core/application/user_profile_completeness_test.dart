import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/application/user_profile_completeness.dart';

// ─────────────────────────────────────────────────────────────────────────────
// isUserProfileComplete
//
// Regression guard for the client login lockout: email signup writes no
// `phone` field (optional since App Store Guideline 5.1.1) and
// `patchUserDocument` never backfills it, so requiring `phone` here rejected
// every such account at login with "Profil incomplet" — permanently.
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> clientSignupDoc({
  Map<String, dynamic>? overrides,
  Set<String> remove = const <String>{},
}) {
  final data = <String, dynamic>{
    'uid': 'c1',
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
    ...?overrides,
  };
  for (final key in remove) {
    data.remove(key);
  }
  return data;
}

void main() {
  group('isUserProfileComplete', () {
    test('email signup account without phone is complete', () {
      expect(isUserProfileComplete(clientSignupDoc()), isTrue);
    });

    test('account with a phone stays complete', () {
      expect(
        isUserProfileComplete(
          clientSignupDoc(overrides: {'phone': '+33612345678'}),
        ),
        isTrue,
      );
    });

    test('city is not required (set later by the login city picker)', () {
      expect(
        isUserProfileComplete(clientSignupDoc(remove: {'city'})),
        isTrue,
      );
    });

    test('legacy doc with role string instead of roles map is complete', () {
      expect(
        isUserProfileComplete(
          clientSignupDoc(overrides: {'role': 'client'}, remove: {'roles'}),
        ),
        isTrue,
      );
    });

    test('merchant onboarding completed is accepted', () {
      expect(
        isUserProfileComplete(
          clientSignupDoc(
            overrides: {
              'merchant_id': 'm1',
              'onboarding': {'merchant': 'completed', 'client': 'completed'},
            },
          ),
        ),
        isTrue,
      );
    });

    test('missing uid is incomplete', () {
      expect(isUserProfileComplete(clientSignupDoc(remove: {'uid'})), isFalse);
    });

    test('missing email is incomplete', () {
      expect(
        isUserProfileComplete(clientSignupDoc(remove: {'email'})),
        isFalse,
      );
    });

    test('missing roles and role is incomplete', () {
      expect(
        isUserProfileComplete(clientSignupDoc(remove: {'roles'})),
        isFalse,
      );
    });

    test('missing status is incomplete', () {
      expect(
        isUserProfileComplete(clientSignupDoc(remove: {'status'})),
        isFalse,
      );
    });

    test('missing merchant_id key is incomplete', () {
      expect(
        isUserProfileComplete(clientSignupDoc(remove: {'merchant_id'})),
        isFalse,
      );
    });

    test('unknown onboarding marker is incomplete', () {
      expect(
        isUserProfileComplete(
          clientSignupDoc(overrides: {'onboarding': {'merchant': 'pending'}}),
        ),
        isFalse,
      );
    });

    test('empty map is incomplete', () {
      expect(isUserProfileComplete(const <String, dynamic>{}), isFalse);
    });

    test('non-string field types do not throw', () {
      expect(
        isUserProfileComplete(
          clientSignupDoc(overrides: {'uid': 42, 'status': 7}),
        ),
        isFalse,
      );
    });
  });
}
