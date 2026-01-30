import 'package:equatable/equatable.dart';
import '../../../../../core/domain/core/failure.dart';
import '../../../../../types.dart';

/// State for the complete login flow
sealed class LoginFlowState extends Equatable {
  const LoginFlowState();

  @override
  List<Object?> get props => const [];
}

/// Initial state - ready to start login
class LoginFlowInitial extends LoginFlowState {
  const LoginFlowInitial();
}

/// Loading state - authentication or profile fetch in progress
class LoginFlowLoading extends LoginFlowState {
  const LoginFlowLoading();
}

/// City selection required - user needs to select a city
class LoginFlowCityRequired extends LoginFlowState {
  const LoginFlowCityRequired(this.uid);
  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Multi-role selection required - user has multiple roles
class LoginFlowMultiRoleRequired extends LoginFlowState {
  const LoginFlowMultiRoleRequired({
    required this.uid,
    required this.roles,
    required this.city,
  });
  final String uid;
  final Map<String, bool> roles;
  final String city;

  @override
  List<Object?> get props => [uid, roles, city];
}

/// Login flow completed successfully - ready to navigate
class LoginFlowSuccess extends LoginFlowState {
  const LoginFlowSuccess({
    required this.uid,
    required this.role,
    required this.city,
    required this.onboardingCompleted,
  });
  final String uid;
  final UserRole role;
  final String city;
  final bool onboardingCompleted;

  @override
  List<Object?> get props => [uid, role, city, onboardingCompleted];
}

/// Login flow error
class LoginFlowError extends LoginFlowState {
  const LoginFlowError(this.failure);
  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

