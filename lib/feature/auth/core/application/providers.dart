import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_user.dart';
import '../domain/entities/user_profile_basics.dart';
import '../../../../core/domain/core/result.dart';
import 'auth_controller.dart';
import 'state/auth_state.dart';
import 'use_cases/sign_out.dart';
import 'use_cases/watch_auth_state.dart';
import 'use_cases/get_user_role.dart';
import 'use_cases/get_user_roles.dart';
import 'use_cases/get_user_city.dart';
import 'use_cases/get_user_profile_basics.dart';
import 'use_cases/update_user_city.dart';
import 'use_cases/get_connected_cities.dart';
import 'use_cases/set_connected_cities.dart';
import 'use_cases/is_merchant_onboarding_completed.dart';
import 'use_cases/patch_user_document.dart';
import 'use_cases/update_last_login_at.dart';
import 'use_cases/check_user_profile_complete.dart';
import '../infrastructure/auth_repository_provider.dart';
import '../infrastructure/user_repository_provider.dart';
import '../infrastructure/role_cache_service.dart';

// Re-export infrastructure providers for use in application layer (for creating use cases)
export '../infrastructure/auth_repository_provider.dart' show authRepositoryProvider;
// Note: roleCacheServiceProvider removed - not implemented yet

// Export navigation state provider
export 'navigation_state_provider.dart' show navigationStateProvider, NavigationState, NavigationLoading, NavigationUnauthenticated, NavigationAuthenticated, NavigationError;

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

/// Current user ID when authenticated, null otherwise (for client features like followed merchants).
final currentUserIdProvider = Provider<String?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is Authenticated ? state.user.id : null;
});

/// Local cache for last selected role (fallback when Firestore role lookup fails).
final roleCacheServiceProvider = Provider<RoleCacheService>((ref) {
  return RoleCacheService();
});

/// Use case provider for getting user role
final getUserRoleProvider = Provider<GetUserRole>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserRole(repository);
});

/// Use case provider for getting user roles map
final getUserRolesProvider = Provider<GetUserRoles>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserRoles(repository);
});

/// Use case provider for getting user city
final getUserCityProvider = Provider<GetUserCity>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserCity(repository);
});

/// Use case provider for getting user email/phone/city (for merchant onboarding).
final getUserProfileBasicsProvider = Provider<GetUserProfileBasics>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserProfileBasics(repository);
});

/// Email / phone / city from Firestore (`/users/{uid}`) for client profile, fidélité, etc.
final userProfileBasicsProvider =
    FutureProvider.family<UserProfileBasics?, String>((ref, uid) async {
  final getBasics = ref.read(getUserProfileBasicsProvider);
  final result = await getBasics.call(uid);
  return result.fold((_) => null, (b) => b);
});

/// Use case provider for updating user city
final updateUserCityProvider = Provider<UpdateUserCity>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateUserCity(repository);
});

/// Use case provider for getting connected cities
final getConnectedCitiesProvider = Provider<GetConnectedCities>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetConnectedCities(repository);
});

/// Use case provider for setting connected cities
final setConnectedCitiesProvider = Provider<SetConnectedCities>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return SetConnectedCities(repository);
});

/// Connected cities for a user (from Firestore). Invalidate to refresh.
final connectedCitiesProvider =
    FutureProvider.family<List<String>, String>((ref, uid) async {
  final getCities = ref.read(getConnectedCitiesProvider);
  final result = await getCities.call(uid);
  return result.fold((_) => <String>[], (list) => list);
});

/// Use case provider for checking merchant onboarding status
final isMerchantOnboardingCompletedProvider =
    Provider<IsMerchantOnboardingCompleted>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return IsMerchantOnboardingCompleted(repository);
});

/// Use case provider for patching user document (legacy migration)
final patchUserDocumentProvider = Provider<PatchUserDocument>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return PatchUserDocument(repository);
});

/// Use case provider for updating last login timestamp
final updateLastLoginAtProvider = Provider<UpdateLastLoginAt>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateLastLoginAt(repository);
});

/// Use case provider for checking profile completeness
final checkUserProfileCompleteProvider = Provider<CheckUserProfileComplete>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return CheckUserProfileComplete(repository);
});
