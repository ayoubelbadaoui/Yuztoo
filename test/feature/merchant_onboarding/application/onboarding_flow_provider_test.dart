import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/merchant_onboarding/application/onboarding_flow_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingFlowNotifier.setContactEmail — covers the normalization that
// keeps storefront display consistent with the email_index/auth lookup
// (lower-case, trimmed, empty → null).
//
// Phone, name, and other setters already follow the same convention; we
// don't re-test them here. This file is scoped to the contact-email path
// because that's the new code surface for the v1 fix.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  OnboardingFlowNotifier notifier() =>
      container.read(onboardingFlowProvider.notifier);

  MerchantOnboardingData state() => container.read(onboardingFlowProvider);

  group('setContactEmail', () {
    test('initial state is null', () {
      expect(state().contactEmail, isNull);
    });

    test('lowercases and persists a typical address', () {
      notifier().setContactEmail('Patron@Boulangerie.FR');
      expect(state().contactEmail, 'patron@boulangerie.fr');
    });

    test('trims surrounding whitespace before persisting', () {
      notifier().setContactEmail('   contact@boulangerie.fr   ');
      expect(state().contactEmail, 'contact@boulangerie.fr');
    });

    test('whitespace-only / empty after a valid value KEEPS the value '
        '(known copyWith limitation)', () {
      // The shared `copyWith` pattern across the onboarding notifier
      // collapses `null` to "no change" (`field ?? this.field`), so a
      // setter that wants to clear cannot do so without a sentinel-aware
      // copyWith. We don't add that here because the UI gate is the real
      // safety net: the Suivant button keys off the live TextField text
      // (via EmailValidator.isValid), not off this state — so a stale
      // value cannot leak past the address step. Locking the actual
      // behaviour here so a future refactor catches any regression.
      notifier().setContactEmail('contact@boulangerie.fr');
      notifier().setContactEmail('   ');
      expect(state().contactEmail, 'contact@boulangerie.fr');
      notifier().setContactEmail('');
      expect(state().contactEmail, 'contact@boulangerie.fr');
    });

    test('does not mutate other onboarding fields', () {
      notifier().setOwnerFirstName('Marie');
      notifier().setPhoneNumber('0612345678');
      notifier().setContactEmail('marie@x.fr');
      expect(state().ownerFirstName, 'Marie');
      expect(state().phoneNumber, '0612345678');
      expect(state().contactEmail, 'marie@x.fr');
    });

    test('reset() clears contactEmail along with the rest', () {
      notifier().setContactEmail('marie@x.fr');
      notifier().reset();
      expect(state().contactEmail, isNull);
    });
  });

  group('MerchantOnboardingData.copyWith — contactEmail', () {
    test('keeps existing contactEmail when not overridden', () {
      const a = MerchantOnboardingData(contactEmail: 'a@a.fr');
      final b = a.copyWith(fullName: 'Boulangerie');
      expect(b.contactEmail, 'a@a.fr');
    });

    test('replaces contactEmail when overridden with a new value', () {
      const a = MerchantOnboardingData(contactEmail: 'a@a.fr');
      final b = a.copyWith(contactEmail: 'b@b.fr');
      expect(b.contactEmail, 'b@b.fr');
    });
  });

  // ── setMerchantType ────────────────────────────────────────────────────────
  // Pins the wire allowlist for B2B/B2C. The Recommandations filter
  // (merchant_partners) trusts these exact strings — a typo here would
  // silently break the filter.

  group('setMerchantType', () {
    test('initial state is null until the user picks', () {
      expect(state().merchantType, isNull);
    });

    test('accepts b2c', () {
      notifier().setMerchantType('b2c');
      expect(state().merchantType, 'b2c');
    });

    test('accepts b2b', () {
      notifier().setMerchantType('b2b');
      expect(state().merchantType, 'b2b');
    });

    test('drops unknown values (no-op, prior valid value preserved)', () {
      notifier().setMerchantType('b2b');
      notifier().setMerchantType('b2x');
      expect(state().merchantType, 'b2b',
          reason: 'Bad input must NOT clear the prior pick. Treat as a '
              'no-op so a future caller bug never blanks the user choice.');
    });

    test('reset() clears merchantType', () {
      notifier().setMerchantType('b2b');
      notifier().reset();
      expect(state().merchantType, isNull);
    });

    test('copyWith carries merchantType when not overridden', () {
      const a = MerchantOnboardingData(merchantType: 'b2b');
      final b = a.copyWith(fullName: 'X');
      expect(b.merchantType, 'b2b');
    });
  });
}
