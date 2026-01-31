import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/application/providers.dart' as auth_core;
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

  Future<void> signIn({required String email, required String password}) async {
    state = const LoginFlowLoading();

    final signInUseCase = ref.read(signInWithEmailPasswordProvider);
    final signInResult = await signInUseCase.call(email: email, password: password);

    await signInResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (authUser) async {
        final getUserRolesUseCase = ref.read(auth_core.getUserRolesProvider);
        final profileCheckResult = await getUserRolesUseCase.call(authUser.id);

        await profileCheckResult.fold(
          (failure) async {
            state = LoginFlowError(failure);
            await ref.read(auth_core.signOutProvider).call();
          },
          (rolesMap) async {
            if (rolesMap == null) {
              state = const LoginFlowError(
                AuthUnexpectedFailure(
                  message: 'Profil utilisateur introuvable. Veuillez vous inscrire via l\'application pour créer votre profil.',
                ),
              );
              await ref.read(auth_core.signOutProvider).call();
              return;
            }

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

                if (isMultiRole) {
                  state = LoginFlowMultiRoleRequired(
                    uid: authUser.id,
                    roles: rolesMap,
                    city: city,
                  );
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
            if (rolesMap == null) {
              state = const LoginFlowError(
                AuthUnexpectedFailure(
                  message: 'Profil utilisateur introuvable. Veuillez vous inscrire via l\'application pour créer votre profil.',
                ),
              );
              await ref.read(auth_core.signOutProvider).call();
              return;
            }
            final hasClientRole = rolesMap['client'] == true;
            final hasMerchantRole = rolesMap['merchant'] == true;
            final isMultiRole = hasClientRole && hasMerchantRole;

            if (isMultiRole) {
              state = LoginFlowMultiRoleRequired(
                uid: uid,
                roles: rolesMap,
                city: city,
              );
            } else {
              final selectedRole =
                  hasClientRole ? UserRole.client : UserRole.merchant;
              await _handleRoleSelectionAndRouting(uid, selectedRole, city, rolesMap);
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
        if (rolesMap == null) {
          state = const LoginFlowError(
            AuthUnexpectedFailure(
              message: 'Profil utilisateur introuvable. Veuillez vous inscrire via l\'application pour créer votre profil.',
            ),
          );
          await ref.read(auth_core.signOutProvider).call();
          return;
        }
        await _handleRoleSelectionAndRouting(uid, selectedRole, city, rolesMap);
      },
    );
  }

  Future<void> _handleRoleSelectionAndRouting(
    String uid,
    UserRole selectedRole,
    String city,
    Map<String, bool> rolesMap,
  ) async {
    final roleCacheService = ref.read(auth_core.roleCacheServiceProvider);
    await roleCacheService.saveLastSelectedRole(selectedRole);

    final isOnboardingCompletedUseCase =
        ref.read(auth_core.isMerchantOnboardingCompletedProvider);
    final onboardingResult = await isOnboardingCompletedUseCase.call(uid);

    await onboardingResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (onboardingCompleted) async {
        final actualOnboardingCompleted = onboardingCompleted ?? false;
        state = LoginFlowSuccess(
          uid: uid,
          role: selectedRole,
          city: city,
          onboardingCompleted: actualOnboardingCompleted,
        );
      },
    );
  }
}

