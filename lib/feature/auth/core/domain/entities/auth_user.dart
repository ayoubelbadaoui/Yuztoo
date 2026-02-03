import 'package:equatable/equatable.dart';
// This file is in auth/core - shared between login and signup features

/// Domain representation of the authenticated user.
/// 
/// Note: The [role] field is a fallback for backward compatibility.
/// The authoritative source for user roles is the roles map in Firestore
/// (Map<String, bool> with keys: "client", "merchant", "provider").
/// This single role string should only be used as a fallback when
/// Firestore data is unavailable.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = 'client',
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  /// Fallback role string (deprecated - use roles map from Firestore instead)
  final String role;

  @override
  List<Object?> get props => <Object?>[id, email, displayName, photoUrl, phoneNumber, role];
}
