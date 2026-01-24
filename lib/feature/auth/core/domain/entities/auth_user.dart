import 'package:equatable/equatable.dart';
// This file is in auth/core - shared between login and signup features

/// Domain representation of the authenticated user.
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
  final String role;

  @override
  List<Object?> get props => <Object?>[id, email, displayName, photoUrl, phoneNumber, role];
}
