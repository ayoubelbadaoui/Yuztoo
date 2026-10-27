import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feature/auth/core/application/providers.dart';
import '../../feature/auth/core/application/state/auth_state.dart';
import '../../feature/auth/login/application/providers.dart';

/// Opt-in local debug sign-in. Never enabled unless both dart-defines are set:
/// `--dart-define=DEBUG_AUTO_LOGIN_EMAIL=...`
/// `--dart-define=DEBUG_AUTO_LOGIN_PASSWORD=...`
const String kDebugAutoLoginEmail =
    String.fromEnvironment('DEBUG_AUTO_LOGIN_EMAIL');
const String kDebugAutoLoginPassword =
    String.fromEnvironment('DEBUG_AUTO_LOGIN_PASSWORD');

/// Runs once after Firebase/auth are ready when debug credentials are provided.
final debugAutoLoginProvider = FutureProvider<void>((ref) async {
  if (kDebugAutoLoginEmail.isEmpty || kDebugAutoLoginPassword.isEmpty) {
    return;
  }

  // Wait until the auth stream leaves the initial/loading states.
  AuthState state = ref.read(authControllerProvider);
  if (state is AuthInitial || state is AuthLoading) {
    await for (final next in ref.read(authControllerProvider.notifier).stream) {
      state = next;
      if (next is! AuthInitial && next is! AuthLoading) break;
    }
  }
  if (state is Authenticated) return;

  await ref.read(signInWithEmailPasswordProvider)(
    email: kDebugAutoLoginEmail,
    password: kDebugAutoLoginPassword,
  );
});
