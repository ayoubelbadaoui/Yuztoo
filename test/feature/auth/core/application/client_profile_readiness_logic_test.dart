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
}
