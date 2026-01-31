import 'package:equatable/equatable.dart';
import '../../../../../core/domain/core/failure.dart';
import '../../../../../types.dart';

sealed class LoginFlowState extends Equatable {
  const LoginFlowState();

  @override
  List<Object?> get props => const [];
}

class LoginFlowInitial extends LoginFlowState {
  const LoginFlowInitial();
}

class LoginFlowLoading extends LoginFlowState {
  const LoginFlowLoading();
}

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

class LoginFlowError extends LoginFlowState {
  const LoginFlowError(this.failure);
  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

class LoginFlowCityRequired extends LoginFlowState {
  const LoginFlowCityRequired(this.uid);
  final String uid;

  @override
  List<Object?> get props => [uid];
}

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

