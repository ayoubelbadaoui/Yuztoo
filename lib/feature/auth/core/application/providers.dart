import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_user.dart';
import '../../../../core/domain/core/result.dart';
import 'auth_controller.dart';
import 'state/auth_state.dart';
import 'use_cases/sign_out.dart';
import 'use_cases/watch_auth_state.dart';
import 'use_cases/get_user_role.dart';
import '../infrastructure/auth_repository_provider.dart';
import '../infrastructure/user_repository_provider.dart';

final signOutProvider = Provider<SignOut>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOut(repository);
});

final watchAuthStateProvider = Provider<WatchAuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return WatchAuthState(repository);
});

/// Exposes raw auth stream results (useful for listeners).
final authResultStreamProvider = StreamProvider<Result<AuthUser?>>((ref) {
  return ref.watch(watchAuthStateProvider)();
});

/// Auth controller provider (moved from login feature to core for shared use)
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    signOut: ref.watch(signOutProvider),
    watchAuthState: ref.watch(watchAuthStateProvider),
  );
});

/// Exposes auth state as a convenience for UI widgets.
final authStateProvider =
    Provider<AuthState>((ref) => ref.watch(authControllerProvider));

/// Use case provider for getting user role
final getUserRoleProvider = Provider<GetUserRole>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserRole(repository);
});

