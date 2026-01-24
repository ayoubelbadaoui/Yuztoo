import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/application/auth_controller.dart';
import '../../core/application/state/auth_state.dart';
import '../../core/domain/entities/auth_user.dart';
import '../../../../core/domain/core/result.dart';
import 'sign_in_with_email_password.dart';

class LoginController extends AuthController {
  LoginController({
    required SignInWithEmailPassword signInWithEmailPassword,
    required super.signOut,
    required super.watchAuthState,
  })  : _signInWithEmailPassword = signInWithEmailPassword,
        super();

  final SignInWithEmailPassword _signInWithEmailPassword;

  Future<void> signIn(String email, String password) async {
    state = const AuthLoading();
    final result =
        await _signInWithEmailPassword(email: email, password: password);
    state = result.fold<AuthState>(
      (failure) => AuthError(failure),
      (user) => Authenticated(user),
    );
  }
}

