import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/merchant_onboarding/application/skip_personal_info_resolution.dart';

// ─────────────────────────────────────────────────────────────────────────────
// resolveMerchantOnboardingSkipPersonalInfo contract.
//
// The dual-profile fix routes `_isDualProfile` through to the merchant
// onboarding wizard so existing clients aren't re-asked for first name, last
// name, and date of birth. This test pins the safety net: skipping is ONLY
// honored when all three fields are actually present on the client account —
// so a half-completed client (signed-up via OTP/OAuth, never finished client
// onboarding) does not silently end up with a merchant doc missing identity
// fields.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('resolveMerchantOnboardingSkipPersonalInfo', () {
    test('returns false when caller did not request a skip', () {
      expect(
        resolveMerchantOnboardingSkipPersonalInfo(
          requested: false,
          firstName: 'Ada',
          lastName: 'Lovelace',
          dateOfBirth: DateTime(1990, 1, 1),
        ),
        isFalse,
        reason: 'New-merchant signup path must always show the full wizard.',
      );
    });

    test('returns true when all three personal fields are populated', () {
      expect(
        resolveMerchantOnboardingSkipPersonalInfo(
          requested: true,
          firstName: 'Ada',
          lastName: 'Lovelace',
          dateOfBirth: DateTime(1990, 1, 1),
        ),
        isTrue,
      );
    });

    test('returns false when firstName is null', () {
      expect(
        resolveMerchantOnboardingSkipPersonalInfo(
          requested: true,
          firstName: null,
          lastName: 'Lovelace',
          dateOfBirth: DateTime(1990, 1, 1),
        ),
        isFalse,
      );
    });

    test('returns false when firstName is whitespace', () {
      expect(
        resolveMerchantOnboardingSkipPersonalInfo(
          requested: true,
          firstName: '   ',
          lastName: 'Lovelace',
          dateOfBirth: DateTime(1990, 1, 1),
        ),
        isFalse,
        reason:
            'Whitespace-only legacy values must be treated as missing so the '
            'user provides a real name.',
      );
    });

    test('returns false when lastName is empty', () {
      expect(
        resolveMerchantOnboardingSkipPersonalInfo(
          requested: true,
          firstName: 'Ada',
          lastName: '',
          dateOfBirth: DateTime(1990, 1, 1),
        ),
        isFalse,
      );
    });

    test('returns false when dateOfBirth is null', () {
      expect(
        resolveMerchantOnboardingSkipPersonalInfo(
          requested: true,
          firstName: 'Ada',
          lastName: 'Lovelace',
          dateOfBirth: null,
        ),
        isFalse,
        reason:
            'OAuth/OTP signup never asks for DOB — that field is the most '
            'common missing piece on legacy clients upgrading to merchant.',
      );
    });
  });
}
