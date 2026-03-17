import 'package:equatable/equatable.dart';

/// Minimal user profile fields needed to complete merchant onboarding.
///
/// Sourced from `/users/{uid}` in Firestore.
final class UserProfileBasics extends Equatable {
  const UserProfileBasics({
    required this.email,
    required this.phone,
    required this.city,
  });

  final String email;
  final String phone;
  final String city;

  @override
  List<Object?> get props => <Object?>[email, phone, city];
}


