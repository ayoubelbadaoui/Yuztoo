import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/client_profile_readiness_logic.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/client_profile_readiness.dart';

void main() {
  test('computeMissingClientProfileFields lists all gaps', () {
    final missing = computeMissingClientProfileFields(
      firstName: null,
      lastName: 'Dupont',
      dateOfBirth: null,
      city: '',
      photoUrl: null,
    );
    expect(missing, contains(ClientProfileMissingField.firstName));
    expect(missing, contains(ClientProfileMissingField.dateOfBirth));
    expect(missing, contains(ClientProfileMissingField.city));
    expect(missing, contains(ClientProfileMissingField.photo));
    expect(missing, isNot(contains(ClientProfileMissingField.lastName)));
  });

  test('computeMissingClientProfileFields empty when complete', () {
    final missing = computeMissingClientProfileFields(
      firstName: 'Marie',
      lastName: 'Martin',
      dateOfBirth: DateTime(1990, 5, 12),
      city: 'Lyon',
      photoUrl: 'https://example.com/a.jpg',
    );
    expect(missing, isEmpty);
  });

  test('buildClientDisplayName prefers first + last', () {
    expect(
      buildClientDisplayName(
        firstName: 'Jean',
        lastName: 'Martin',
        fallbackDisplayName: 'Ignored',
      ),
      'Jean Martin',
    );
  });

  group('ClientProfileReadiness re-entry gate', () {
    // Regression: a client account created with a skipped photo (which the
    // onboarding wizard explicitly allows) was bounced back into onboarding
    // on every merchant→client switch because the gate required photo+city.
    test('photo and city gaps do NOT block client home re-entry', () {
      const readiness = ClientProfileReadiness(
        hasClientRole: true,
        onboardingCompleted: true,
        missingForClientHome: [
          ClientProfileMissingField.photo,
          ClientProfileMissingField.city,
        ],
      );
      expect(readiness.canEnterClientHomeDirectly, isTrue);
      expect(readiness.hasRequiredIdentityData, isTrue);
      expect(readiness.isProfileDataComplete, isFalse);
      // Optional gaps must not be announced in the confirmation dialog.
      expect(readiness.missingFieldsLabelFr, isEmpty);
    });

    test('missing identity fields DO block re-entry', () {
      const readiness = ClientProfileReadiness(
        hasClientRole: true,
        onboardingCompleted: false,
        missingForClientHome: [
          ClientProfileMissingField.firstName,
          ClientProfileMissingField.dateOfBirth,
          ClientProfileMissingField.photo,
        ],
      );
      expect(readiness.canEnterClientHomeDirectly, isFalse);
      expect(readiness.missingRequiredFields, [
        ClientProfileMissingField.firstName,
        ClientProfileMissingField.dateOfBirth,
      ]);
      // Dialog copy lists identity gaps only — photo is omitted.
      expect(readiness.missingFieldsLabelFr, 'prénom, date de naissance');
    });

    test('missing client role blocks re-entry even with full identity', () {
      const readiness = ClientProfileReadiness(
        hasClientRole: false,
        onboardingCompleted: false,
        missingForClientHome: [],
      );
      expect(readiness.canEnterClientHomeDirectly, isFalse);
      expect(readiness.hasRequiredIdentityData, isTrue);
    });
  });
}
