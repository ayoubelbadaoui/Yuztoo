import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_user.dart';
import '../../../../core/domain/core/result.dart';
import 'state/auth_state.dart';
import 'use_cases/sign_out.dart';
import 'use_cases/watch_auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required SignOut signOut,
    required WatchAuthState watchAuthState,
  })  : _signOut = signOut,
        _watchAuthState = watchAuthState,
        super(const AuthInitial()) {
    _listenToAuthStream();
  }

  final SignOut _signOut;
  final WatchAuthState _watchAuthState;

  StreamSubscription<Result<AuthUser?>>? _authSubscription;

  Future<void> signOut() async {
    state = const AuthLoading();
    final result = await _signOut();
    state = result.fold<AuthState>(
      (failure) => AuthError(failure),
      (_) => const Unauthenticated(),
    );
  }

  void _listenToAuthStream() {
    _authSubscription?.cancel();
    _authSubscription = _watchAuthState().listen((result) {
      state = result.fold<AuthState>(
        (failure) => AuthError(failure),
        (user) => user == null ? const Unauthenticated() : Authenticated(user),
      );
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
