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

  /// Fields the client onboarding wizard itself hard-requires
  /// (see ClientOnboardingScreen._finish: first name, last name and
  /// date of birth block the finish button; the photo step is skippable
  /// and city can stay empty).
  ///
  /// The re-entry gate below MUST stay in sync with this set: requiring
  /// more here than onboarding does means a valid, completed client
  /// account gets bounced back into the wizard on every role switch —
  /// "le compte existe déjà mais on me redemande mes infos".
  static const Set<ClientProfileMissingField> requiredFields = {
    ClientProfileMissingField.firstName,
    ClientProfileMissingField.lastName,
    ClientProfileMissingField.dateOfBirth,
  };

  final bool hasClientRole;
  final bool onboardingCompleted;
  final List<ClientProfileMissingField> missingForClientHome;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? city;
  final String? photoUrl;
  final String? displayName;

  /// Strict completeness — every field including the optional ones
  /// (photo, city). Useful for profile-completion nudges, NOT for
  /// gating access to the client home.
  bool get isProfileDataComplete => missingForClientHome.isEmpty;

  /// Required identity gaps only. Photo and city never appear here.
  List<ClientProfileMissingField> get missingRequiredFields =>
      missingForClientHome.where(requiredFields.contains).toList();

  /// True when the identity data onboarding enforces is present —
  /// the client account is usable even if photo / city were skipped.
  bool get hasRequiredIdentityData => missingRequiredFields.isEmpty;

  /// Dual-profile merchants can have full client data in Firestore while
  /// `onboarding.client` still says `not_started`. The real gate is role +
  /// the fields onboarding actually requires — never the optional ones,
  /// and do not force [ClientOnboardingScreen] on every switch.
  bool get canEnterClientHomeDirectly =>
      hasClientRole && hasRequiredIdentityData;

  /// French list of the missing REQUIRED fields, for the confirmation
  /// dialog. Optional gaps (photo, city) are deliberately not announced:
  /// telling the user "il nous manque : photo de profil" for an account
  /// that already works reads as a bug.
  String get missingFieldsLabelFr => missingRequiredFields
      .map((f) => f.labelFr)
      .join(', ');
}
