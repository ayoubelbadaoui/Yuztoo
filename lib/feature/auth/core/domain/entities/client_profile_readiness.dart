/// Fields required before a merchant can use the app as a client without
/// walking through [ClientOnboardingScreen].
enum ClientProfileMissingField {
  firstName,
  lastName,
  dateOfBirth,
  city,
  photo,
}

extension ClientProfileMissingFieldLabels on ClientProfileMissingField {
  String get labelFr => switch (this) {
        ClientProfileMissingField.firstName => 'prénom',
        ClientProfileMissingField.lastName => 'nom',
        ClientProfileMissingField.dateOfBirth => 'date de naissance',
        ClientProfileMissingField.city => 'ville',
        ClientProfileMissingField.photo => 'photo de profil',
      };
}

/// Snapshot used when a merchant switches to the client role.
final class ClientProfileReadiness {
  const ClientProfileReadiness({
    required this.hasClientRole,
    required this.onboardingCompleted,
    required this.missingForClientHome,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.city,
    this.photoUrl,
    this.displayName,
  });

  final bool hasClientRole;
  final bool onboardingCompleted;
  final List<ClientProfileMissingField> missingForClientHome;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? city;
  final String? photoUrl;
  final String? displayName;

  bool get isProfileDataComplete => missingForClientHome.isEmpty;

  bool get canEnterClientHomeDirectly =>
      hasClientRole && onboardingCompleted && isProfileDataComplete;

  String get missingFieldsLabelFr => missingForClientHome
      .map((f) => f.labelFr)
      .join(', ');
}
