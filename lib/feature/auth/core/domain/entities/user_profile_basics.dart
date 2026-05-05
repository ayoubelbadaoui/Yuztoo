import 'package:equatable/equatable.dart';

/// Minimal user profile fields needed across onboarding and profile screens.
///
/// Sourced from `/users/{uid}` in Firestore.
final class UserProfileBasics extends Equatable {
  const UserProfileBasics({
    required this.email,
    required this.phone,
    required this.city,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
  });

  final String email;
  final String phone;
  final String city;

  /// Owner / personal first name (separate from displayName).
  final String? firstName;

  /// Owner / personal last name (separate from displayName).
  final String? lastName;

  /// Date of birth — used for birthday notifications and identity.
  final DateTime? dateOfBirth;

  @override
  List<Object?> get props => <Object?>[email, phone, city, firstName, lastName, dateOfBirth];
}


