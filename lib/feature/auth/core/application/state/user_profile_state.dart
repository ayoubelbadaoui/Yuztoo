import 'package:equatable/equatable.dart';

/// Represents the full user profile state (roles, city, etc.)
/// This is cached in memory for the session
class UserProfileState extends Equatable {
  const UserProfileState({
    required this.uid,
    required this.email,
    this.phone,
    required this.roles,
    this.city,
    this.onboardingCompleted,
  });

  final String uid;
  final String email;
  final String? phone;
  final Map<String, bool> roles;
  final String? city;
  final bool? onboardingCompleted; // For merchants

  bool get isClient => roles['client'] == true;
  bool get isMerchant => roles['merchant'] == true;
  bool get isMultiRole => isClient && isMerchant;

  UserProfileState copyWith({
    String? uid,
    String? email,
    String? phone,
    Map<String, bool>? roles,
    String? city,
    bool? onboardingCompleted,
  }) {
    return UserProfileState(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roles: roles ?? this.roles,
      city: city ?? this.city,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props => [uid, email, phone, roles, city, onboardingCompleted];
}

