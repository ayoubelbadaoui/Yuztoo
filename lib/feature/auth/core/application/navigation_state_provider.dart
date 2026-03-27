import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../types.dart';
import '../domain/entities/auth_user.dart';
import '../infrastructure/user_repository_provider.dart';
import 'providers.dart';
import 'state/auth_state.dart';

/// Navigation state that determines which screen should be displayed
/// based on auth state, user role, and onboarding status.
///
/// Returns null while loading or if user document is missing (should trigger sign out).
sealed class NavigationState {
  const NavigationState();
}

/// Initial state - app is loading auth state
class NavigationLoading extends NavigationState {
  const NavigationLoading();
}

/// Unauthenticated state - show auth flow screens
class NavigationUnauthenticated extends NavigationState {
  const NavigationUnauthenticated(this.screen);
  final ScreenId screen; // splash or roleSelection
}

/// Authenticated state - show appropriate home screen based on role and onboarding
class NavigationAuthenticated extends NavigationState {
  const NavigationAuthenticated(this.screen);
  final ScreenId
      screen; // clientHome, merchantDashboard, or merchantProfileForm
}

/// Error state - user document missing or error fetching user data
/// Should trigger sign out
class NavigationError extends NavigationState {
  const NavigationError();
}

/// Provider that computes navigation state from auth state, role, and onboarding status.
/// Uses Provider that watches authControllerProvider and returns AsyncValue for async operations.
/// This ensures navigation updates immediately when auth state changes (e.g., after login).
final navigationStateProvider = Provider<AsyncValue<NavigationState>>((ref) {
  // Watch authControllerProvider - this is reactive and updates automatically
  final authState = ref.watch(authControllerProvider);

  // Handle different auth states synchronously
  // Start with splash screen instead of loading to prevent stuck state
  if (authState is AuthInitial) {
    // Initial state - show splash while auth stream initializes
    return const AsyncValue.data(NavigationUnauthenticated(ScreenId.splash));
  }

  if (authState is AuthLoading) {
    return const AsyncValue.data(NavigationLoading());
  }

  if (authState is Unauthenticated) {
    return const AsyncValue.data(NavigationUnauthenticated(ScreenId.splash));
  }

  if (authState is AuthError) {
    return const AsyncValue.data(
        NavigationUnauthenticated(ScreenId.roleSelection));
  }

  if (authState is Authenticated) {
    // For authenticated users, we need async operations (get role, check onboarding)
    // Watch the future provider which will handle async computation
    return ref.watch(_authenticatedNavigationProvider(authState.user));
  }

  // Fallback - show splash
  return const AsyncValue.data(NavigationUnauthenticated(ScreenId.splash));
});

/// Helper provider that computes navigation state for authenticated users
final _authenticatedNavigationProvider =
    FutureProvider.family<NavigationState, AuthUser>((ref, user) async {
  return await _computeNavigationStateForUser(ref, user);
});

/// Helper function to compute navigation state for an authenticated user
Future<NavigationState> _computeNavigationStateForUser(
    Ref ref, AuthUser user) async {
  // Get user role
  final getUserRole = ref.read(getUserRoleProvider);
  final roleResult = await getUserRole.call(user.id);

  final role = roleResult.fold(
    (_) => null, // Error getting role
    (r) => r, // Role or null if not found
  );

  // Missing user document or error → trigger sign out
  if (role == null) {
    return const NavigationError();
  }

  // Client role → go to client home
  if (role == UserRole.client) {
    return const NavigationAuthenticated(ScreenId.clientHome);
  }

  // Merchant: same helper as [main] — Firestore onboarding gate.
  if (role == UserRole.merchant) {
    final completed = await merchantOnboardingCompletedFromFirestore(
      ref.read(userRepositoryProvider),
      user.id,
    );
    return NavigationAuthenticated(
      completed ? ScreenId.merchantDashboard : ScreenId.merchantProfileForm,
    );
  }

  // Fallback - should not reach here
  return const NavigationUnauthenticated(ScreenId.roleSelection);
}
