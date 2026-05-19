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

  /// Dual-profile merchants can have full client data in Firestore while
  /// `onboarding.client` still says `not_started`. The real gate is role +
  /// required fields — do not force [ClientOnboardingScreen] on every switch.
  bool get canEnterClientHomeDirectly =>
      hasClientRole && isProfileDataComplete;

  String get missingFieldsLabelFr => missingForClientHome
      .map((f) => f.labelFr)
      .join(', ');
}
