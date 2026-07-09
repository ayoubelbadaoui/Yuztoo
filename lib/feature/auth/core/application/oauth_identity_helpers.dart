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
  final directFirst = user.firstName?.trim() ?? '';
  final directLast = user.lastName?.trim() ?? '';
  if (directFirst.isNotEmpty || directLast.isNotEmpty) {
    final dn = user.displayName?.trim() ?? '';
    return (
      firstName: directFirst.isNotEmpty ? directFirst : null,
      lastName: directLast.isNotEmpty ? directLast : null,
      displayName: dn.isNotEmpty
          ? dn
          : _composeDisplayName(
              firstName: directFirst.isNotEmpty ? directFirst : null,
              lastName: directLast.isNotEmpty ? directLast : null,
              fallback: null,
            ),
      photoUrl: isUsableOAuthProfilePhotoUrl(user.photoUrl?.trim() ?? '')
          ? user.photoUrl!.trim()
          : null,
    );
  }
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

String? _composeDisplayName({
  String? firstName,
  String? lastName,
  String? fallback,
}) {
  final f = firstName?.trim() ?? '';
  final l = lastName?.trim() ?? '';
  if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
  if (f.isNotEmpty) return f;
  if (l.isNotEmpty) return l;
  final fb = fallback?.trim() ?? '';
  return fb.isEmpty ? null : fb;
}
