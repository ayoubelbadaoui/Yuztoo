import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/domain/entities/client_profile_readiness.dart';

void main() {
  group('ClientProfileReadiness', () {
    test('requiredFields are only first and last name', () {
      expect(
        ClientProfileReadiness.requiredFields,
        {
          ClientProfileMissingField.firstName,
          ClientProfileMissingField.lastName,
        },
      );
      expect(
        ClientProfileReadiness.requiredFields.contains(
          ClientProfileMissingField.city,
        ),
        isFalse,
      );
      expect(
        ClientProfileReadiness.requiredFields.contains(
          ClientProfileMissingField.photo,
        ),
        isFalse,
      );
      expect(
        ClientProfileReadiness.requiredFields.contains(
          ClientProfileMissingField.dateOfBirth,
        ),
        isFalse,
      );
    });

    test('canEnterClientHomeDirectly with names only (city/photo/dob optional)', () {
      const readiness = ClientProfileReadiness(
        hasClientRole: true,
        onboardingCompleted: false,
        missingForClientHome: [
          ClientProfileMissingField.city,
          ClientProfileMissingField.photo,
          ClientProfileMissingField.dateOfBirth,
        ],
        firstName: 'Julie',
        lastName: 'Daminelli',
      );

      expect(readiness.hasRequiredIdentityData, isTrue);
      expect(readiness.canEnterClientHomeDirectly, isTrue);
      expect(readiness.missingRequiredFields, isEmpty);
      expect(readiness.isProfileDataComplete, isFalse);
    });

    test('cannot enter home when first name missing', () {
      const readiness = ClientProfileReadiness(
        hasClientRole: true,
        onboardingCompleted: false,
        missingForClientHome: [ClientProfileMissingField.firstName],
        lastName: 'Only',
      );

      expect(readiness.hasRequiredIdentityData, isFalse);
      expect(readiness.canEnterClientHomeDirectly, isFalse);
      expect(readiness.missingFieldsLabelFr, 'prénom');
    });
  });
}
