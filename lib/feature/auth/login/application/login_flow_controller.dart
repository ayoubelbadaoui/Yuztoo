import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/application/providers.dart' as auth_core;
import '../../core/domain/entities/auth_user.dart';
import '../../core/domain/auth_failure.dart';
import '../../../../../types.dart';
import '../application/state/login_flow_state.dart';
import 'providers.dart';

class LoginFlowController extends StateNotifier<LoginFlowState> {
  LoginFlowController(this.ref) : super(const LoginFlowInitial());

  final Ref ref;

  /// Reset the login flow to initial state
  /// Useful when user cancels city picker or role selection
  void reset() {
    state = const LoginFlowInitial();
  }

  Future<void> signIn({
    required String email,
    required String password,
    UserRole? preferredRole,
  }) async {
    state = const LoginFlowLoading();

    final signInUseCase = ref.read(signInWithEmailPasswordProvider);
    final signInResult = await signInUseCase.call(email: email, password: password);

    await signInResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (authUser) async {
        // Patch missing fields for legacy users (non-blocking - don't fail login if this fails)
        try {
          final patchUserDocUseCase = ref.read(auth_core.patchUserDocumentProvider);
          await patchUserDocUseCase.call(authUser.id);
          // Ignore errors - patching is best effort for legacy migration
        } catch (_) {
          // Continue login even if patching fails
        }

        // Update last_login_at timestamp (non-blocking - don't fail login if this fails)
        try {
          final updateLastLoginUseCase = ref.read(auth_core.updateLastLoginAtProvider);
          await updateLastLoginUseCase.call(authUser.id);
          // Ignore errors - last_login_at update is non-critical
        } catch (_) {
          // Continue login even if last_login_at update fails
        }

        // Check profile completeness after patching
        final checkProfileCompleteUseCase = ref.read(auth_core.checkUserProfileCompleteProvider);
        final profileCompleteResult = await checkProfileCompleteUseCase.call(authUser.id);
        final isProfileComplete = profileCompleteResult.fold(
          (_) => true, // On error, assume complete to not block login
          (complete) => complete,
        );

        if (!isProfileComplete) {
          state = const LoginFlowError(ProfileIncompleteFailure());
          return;
        }

        final rolesMap = await _resolveRoles(authUser);
        final getUserCityUseCase = ref.read(auth_core.getUserCityProvider);
        final cityResult = await getUserCityUseCase.call(authUser.id);
        await cityResult.fold(
          (failure) async {
            state = LoginFlowError(failure);
          },
          (city) async {
            if (city == null || city.isEmpty) {
              state = LoginFlowCityRequired(authUser.id);
              return;
            }

            final hasClientRole = rolesMap['client'] == true;
            final hasMerchantRole = rolesMap['merchant'] == true;
            final isMultiRole = hasClientRole && hasMerchantRole;

            // Check if user requested a specific role but doesn't have it
            if (preferredRole != null) {
              final hasRequestedRole = (preferredRole == UserRole.merchant && hasMerchantRole) ||
                  (preferredRole == UserRole.client && hasClientRole);
              
              if (!hasRequestedRole) {
                // User doesn't have the requested role
                state = LoginFlowRoleMismatch(
                  uid: authUser.id,
                  requestedRole: preferredRole,
                  availableRoles: rolesMap,
                );
                return;
              }
            }

            if (isMultiRole) {
              // If user has multiple roles, show selection dialog unless they requested a specific role
              if (preferredRole != null) {
                // User requested a specific role and has it - use that
                await _handleRoleSelectionAndRouting(
                  authUser.id,
                  preferredRole,
                  city,
                  rolesMap,
                );
              } else {
                // Show role selection dialog
                state = LoginFlowMultiRoleRequired(
                  uid: authUser.id,
                  roles: rolesMap,
                  city: city,
                );
              }
            } else {
              final selectedRole =
                  hasClientRole ? UserRole.client : UserRole.merchant;
              await _handleRoleSelectionAndRouting(
                authUser.id,
                selectedRole,
                city,
                rolesMap,
              );
            }
          },
        );
      },
    );
  }

  Future<void> updateCity(String uid, String city) async {
    state = const LoginFlowLoading();
    final updateUserCityUseCase = ref.read(auth_core.updateUserCityProvider);
    final updateResult = await updateUserCityUseCase.call(uid: uid, city: city);

    await updateResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (_) async {
        // City updated, now proceed with role-based routing
        final getUserRolesUseCase = ref.read(auth_core.getUserRolesProvider);
        final rolesResult = await getUserRolesUseCase.call(uid);
        await rolesResult.fold(
          (failure) async {
            state = LoginFlowError(failure);
          },
          (rolesMap) async {
            // Use fallback roles if rolesMap is null (don't sign out - use fallback)
            final effectiveRolesMap = rolesMap ?? <String, bool>{
              'client': true, // Default to client if roles missing
              'merchant': false,
              'provider': false,
            };
            
            final hasClientRole = effectiveRolesMap['client'] == true;
            final hasMerchantRole = effectiveRolesMap['merchant'] == true;
            final isMultiRole = hasClientRole && hasMerchantRole;

            if (isMultiRole) {
              state = LoginFlowMultiRoleRequired(
                uid: uid,
                roles: effectiveRolesMap,
                city: city,
              );
            } else {
              final selectedRole =
                  hasClientRole ? UserRole.client : UserRole.merchant;
              await _handleRoleSelectionAndRouting(uid, selectedRole, city, effectiveRolesMap);
            }
          },
        );
      },
    );
  }

  Future<void> selectRole(String uid, UserRole selectedRole, String city) async {
    state = const LoginFlowLoading();
    final getUserRolesUseCase = ref.read(auth_core.getUserRolesProvider);
    final rolesResult = await getUserRolesUseCase.call(uid);

    await rolesResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (rolesMap) async {
        // Use fallback roles if rolesMap is null (don't sign out - use fallback)
        // Build roles map based on selected role if rolesMap is missing
        final effectiveRolesMap = rolesMap ?? <String, bool>{
          'client': selectedRole == UserRole.client,
          'merchant': selectedRole == UserRole.merchant,
          'provider': false,
        };
        
        await _handleRoleSelectionAndRouting(uid, selectedRole, city, effectiveRolesMap);
      },
    );
  }

  Future<void> _handleRoleSelectionAndRouting(
    String uid,
    UserRole selectedRole,
    String city,
    Map<String, bool> rolesMap,
  ) async {
    // Persist so main shell / cold start route the same way as login intent (client vs merchant).
    try {
      final roleCacheService = ref.read(auth_core.roleCacheServiceProvider);
      await roleCacheService.saveLastSelectedRole(selectedRole);
    } catch (_) {
      // Non-fatal
    }

    // Only check onboarding for merchants; clients don't need it
    bool actualOnboardingCompleted = false;
    if (selectedRole == UserRole.merchant) {
      try {
        final isOnboardingCompletedUseCase =
            ref.read(auth_core.isMerchantOnboardingCompletedProvider);
        final onboardingResult = await isOnboardingCompletedUseCase.call(uid);
        actualOnboardingCompleted = onboardingResult.fold(
          (_) => false, // On failure, assume incomplete (non-fatal)
          (completed) => completed ?? false,
        );
      } catch (_) {
        // Any exception -> assume incomplete (non-fatal)
        actualOnboardingCompleted = false;
      }
    }

    state = LoginFlowSuccess(
      uid: uid,
      role: selectedRole,
      city: city,
      onboardingCompleted: actualOnboardingCompleted,
    );
  }

  Future<Map<String, bool>> _resolveRoles(AuthUser authUser) async {
    final fallbackRoles = <String, bool>{
      'client': authUser.role.toLowerCase() != 'merchant',
      'merchant': authUser.role.toLowerCase() == 'merchant',
      'provider': false,
    };

    try {
      final getUserRolesUseCase = ref.read(auth_core.getUserRolesProvider);
      final profileCheckResult = await getUserRolesUseCase.call(authUser.id);

      return await profileCheckResult.fold(
        (failure) async {
          // On failure, fall back to authUser role (don’t force sign-out)
          return fallbackRoles;
        },
        (rolesMap) async {
          if (rolesMap == null) {
            // Legacy or missing roles map — use authUser role fallback
            return fallbackRoles;
          }
          return rolesMap;
        },
      );
    } catch (_) {
      // Any unexpected error -> fallback
      return fallbackRoles;
    }
  }
}

