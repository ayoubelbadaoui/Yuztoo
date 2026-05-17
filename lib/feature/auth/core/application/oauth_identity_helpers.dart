import '../../../../core/utils/oauth_profile_photo.dart';
import '../domain/entities/auth_user.dart';

/// Splits a provider display name into first / last for Firestore.
({String? firstName, String? lastName}) splitOAuthDisplayName(String? displayName) {
  final trimmed = displayName?.trim() ?? '';
  if (trimmed.isEmpty) {
    return (firstName: null, lastName: null);
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return (firstName: parts.first, lastName: null);
  }
  return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
}

/// Fields to persist when creating `/users/{uid}` after Google / Apple sign-up.
({
  String? firstName,
  String? lastName,
  String? displayName,
  String? photoUrl,
}) oauthIdentityForCreateUserDocument(AuthUser user) {
  final names = splitOAuthDisplayName(user.displayName);
  final dn = user.displayName?.trim() ?? '';
  final pu = user.photoUrl?.trim() ?? '';
  return (
    firstName: names.firstName,
    lastName: names.lastName,
    displayName: dn.isNotEmpty ? dn : null,
    photoUrl: isUsableOAuthProfilePhotoUrl(pu) ? pu : null,
  );
}
