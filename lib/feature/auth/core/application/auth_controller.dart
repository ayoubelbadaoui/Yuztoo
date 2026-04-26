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
    /// Runs **before** Firebase Auth sign-out so Firestore rules still see
    /// `request.auth.uid` (e.g. delete `users/{uid}/push_tokens/device`).
    Future<void> Function(String uid)? onClearDevicePushToken,
  })  : _signOut = signOut,
        _watchAuthState = watchAuthState,
        _onClearDevicePushToken = onClearDevicePushToken,
        super(const AuthInitial()) {
    _listenToAuthStream();
  }

  final SignOut _signOut;
  final WatchAuthState _watchAuthState;
  final Future<void> Function(String uid)? _onClearDevicePushToken;

  StreamSubscription<Result<AuthUser?>>? _authSubscription;

  Future<void> signOut() async {
    final uid = switch (state) {
      Authenticated(:final user) => user.id,
      _ => null,
    };
    state = const AuthLoading();
    final clearPush = _onClearDevicePushToken;
    if (uid != null && clearPush != null) {
      try {
        await clearPush(uid);
      } catch (_) {}
    }
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

  /// Manually refresh auth state by re-checking current user
  /// This is useful after sign-in to ensure immediate state update
  /// NOTE: This safely re-subscribes - userChanges() will emit current user immediately
  /// so there's no risk of logout (it emits the authenticated user, not null)
  Future<void> refreshAuthState() async {
    // Cancel current subscription and re-listen to get fresh state
    // userChanges() emits the current user immediately on subscription,
    // so this is safe and won't cause logout
    _listenToAuthStream();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
