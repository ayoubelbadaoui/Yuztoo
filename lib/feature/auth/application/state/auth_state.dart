import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_user.dart';
import '../../../../core/domain/core/failure.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => <Object?>[user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.failure);
  final AppFailure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
