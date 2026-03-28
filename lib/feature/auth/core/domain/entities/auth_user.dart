import 'package:equatable/equatable.dart';
// This file is in auth/core - shared between login and signup features

/// Domain representation of the authenticated user.
///
/// Canonical role data is [roles] (same shape as Firestore `users/{uid}.roles`).
/// [primaryRole] is `users/{uid}.primary_role` — first signup intent; login follows this.
/// [role] is a convenience string derived from [roles] when present.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.roles,
    this.primaryRole,
    this.role = 'client',
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  /// `client` / `merchant` / `provider` flags when the profile was loaded from Firestore.
  final Map<String, bool>? roles;
  /// Firestore `primary_role`: `merchant` | `client` — account created as merchant vs client.
  final String? primaryRole;
  /// Primary UI role string derived from [roles] when present.
  final String role;

  bool get isMerchant {
    final p = primaryRole?.toLowerCase();
    if (p == 'merchant') return true;
    if (p == 'client') return false;
    final r = roles;
    if (r != null) return r['merchant'] == true;
    return role.toLowerCase() == 'merchant';
  }

  @override
  List<Object?> get props =>
      <Object?>[id, email, displayName, photoUrl, phoneNumber, roles, primaryRole, role];
}
