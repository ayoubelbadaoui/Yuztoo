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
    this.firstName,
    this.lastName,
    this.roles,
    this.primaryRole,
    this.role = 'client',
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  /// OAuth given name (e.g. Apple `givenName` on first authorization).
  final String? firstName;
  /// OAuth family name (e.g. Apple `familyName` on first authorization).
  final String? lastName;
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

  /// True when the user account currently carries the merchant role
  /// (independent of which role is "primary" / displayed in the UI).
  ///
  /// Use this — NOT [isMerchant] — to decide whether secondary-role
  /// affordances like "Créer un compte pro" should remain visible.
  /// [isMerchant] short-circuits on `primary_role` and so cannot tell
  /// you whether the user *also* holds the merchant role on top of a
  /// primary client identity.
  ///
  /// Resolution order:
  /// 1. The canonical [roles] map when present (Firestore source of truth).
  /// 2. [primaryRole] as a fallback when the roles map was not loaded
  ///    yet (early auth states).
  /// 3. The legacy [role] string as a last resort.
  bool get hasMerchantRole {
    final r = roles;
    if (r != null) return r['merchant'] == true;
    final p = primaryRole?.toLowerCase();
    if (p == 'merchant') return true;
    if (p == 'client') return false;
    return role.toLowerCase() == 'merchant';
  }

  /// Symmetric counterpart to [hasMerchantRole] — true when the user
  /// account currently carries the client role. Same resolution order
  /// and same intent: power role-aware UI gates without leaking the
  /// "primary role" abstraction.
  bool get hasClientRole {
    final r = roles;
    if (r != null) return r['client'] == true;
    final p = primaryRole?.toLowerCase();
    if (p == 'client') return true;
    if (p == 'merchant') return false;
    return role.toLowerCase() == 'client';
  }

  /// True when the account holds BOTH client and merchant roles. Use
  /// to hide secondary-role onboarding CTAs that no longer apply (the
  /// user already created the other carnet / pro account).
  bool get hasBothRoles => hasClientRole && hasMerchantRole;

  @override
  List<Object?> get props => <Object?>[
        id,
        email,
        displayName,
        photoUrl,
        phoneNumber,
        firstName,
        lastName,
        roles,
        primaryRole,
        role,
      ];
}
