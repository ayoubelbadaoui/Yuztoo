import '../domain/entities/client_profile_readiness.dart';

/// Derives which client-profile fields are still empty on `/users/{uid}`.
List<ClientProfileMissingField> computeMissingClientProfileFields({
  String? firstName,
  String? lastName,
  DateTime? dateOfBirth,
  String? city,
  String? photoUrl,
}) {
  final missing = <ClientProfileMissingField>[];
  if (firstName == null || firstName.trim().isEmpty) {
    missing.add(ClientProfileMissingField.firstName);
  }
  if (lastName == null || lastName.trim().isEmpty) {
    missing.add(ClientProfileMissingField.lastName);
  }
  if (dateOfBirth == null) {
    missing.add(ClientProfileMissingField.dateOfBirth);
  }
  if (city == null || city.trim().isEmpty) {
    missing.add(ClientProfileMissingField.city);
  }
  if (photoUrl == null || photoUrl.trim().isEmpty) {
    missing.add(ClientProfileMissingField.photo);
  }
  return missing;
}

String buildClientDisplayName({
  String? firstName,
  String? lastName,
  String? fallbackDisplayName,
}) {
  final fromParts = [firstName, lastName]
      .where((s) => s != null && s.trim().isNotEmpty)
      .map((s) => s!.trim())
      .join(' ')
      .trim();
  if (fromParts.isNotEmpty) return fromParts;
  final fallback = fallbackDisplayName?.trim() ?? '';
  return fallback;
}
