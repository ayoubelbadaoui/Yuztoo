import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/repositories/user_repository.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/domain/auth_failure.dart';
import '../../../../types.dart';
import 'sign_in_with_email_password.dart';
import 'state/login_flow_state.dart';

/// Controller for the complete login flow
/// 
/// Orchestrates: sign in → fetch profile → check city → check roles → determine routing
class LoginFlowController extends StateNotifier<LoginFlowState> {
  LoginFlowController({
    required SignInWithEmailPassword signInWithEmailPassword,
    required UserRepository userRepository,
    required AuthRepository authRepository,
  })  : _signInWithEmailPassword = signInWithEmailPassword,
        _userRepository = userRepository,
        _authRepository = authRepository,
        super(const LoginFlowInitial());

  final SignInWithEmailPassword _signInWithEmailPassword;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  /// Start the complete login flow
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const LoginFlowLoading();

    // Step 1: Sign in with email and password
    final signInResult = await _signInWithEmailPassword(
      email: email,
      password: password,
    );

    await signInResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (authUser) async {
        // Step 2: Fetch user profile to verify it exists
        await _handleProfileFetch(authUser.id);
      },
    );
  }

  /// Handle profile fetch and continue flow
  Future<void> _handleProfileFetch(String uid) async {
    final roleResult = await _userRepository.getUserRole(uid);
    
    await roleResult.fold(
      (failure) async {
        // Profile fetch failed - sign out and show error
        await _authRepository.signOut();
        state = LoginFlowError(failure);
      },
      (role) async {
        if (role == null) {
          // Profile doesn't exist - sign out and show error
          await _authRepository.signOut();
          state = const LoginFlowError(
            AuthUnexpectedFailure(message: 'Profil utilisateur introuvable.'),
          );
        } else {
          // Profile exists - check city
          await _handleCityCheck(uid, role);
        }
      },
    );
  }

  /// Handle city check and continue flow
  Future<void> _handleCityCheck(String uid, UserRole role) async {
    final cityResult = await _userRepository.getUserCity(uid);
    
    await cityResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (city) async {
        if (city == null || city.isEmpty) {
          // City is missing - require city selection
          state = LoginFlowCityRequired(uid);
        } else {
          // City exists - check for multi-role
          await _handleRoleCheck(uid, city);
        }
      },
    );
  }

  /// Handle role check and determine if multi-role selection is needed
  Future<void> _handleRoleCheck(String uid, String city) async {
    final rolesResult = await _userRepository.getUserRoles(uid);
    
    await rolesResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (roles) async {
        if (roles == null) {
          state = const LoginFlowError(
            AuthUnexpectedFailure(message: 'Impossible de récupérer les rôles utilisateur.'),
          );
          return;
        }

        final isClient = roles['client'] == true;
        final isMerchant = roles['merchant'] == true;

        if (isClient && isMerchant) {
          // Multi-role user - show selection dialog
          state = LoginFlowMultiRoleRequired(
            uid: uid,
            roles: roles,
            city: city,
          );
        } else if (isMerchant) {
          // Merchant only - check onboarding
          await _handleMerchantOnboarding(uid, city);
        } else {
          // Client only - complete flow
          state = LoginFlowSuccess(
            uid: uid,
            role: UserRole.client,
            city: city,
            onboardingCompleted: true, // Clients don't have onboarding
          );
        }
      },
    );
  }

  /// Handle merchant onboarding check
  Future<void> _handleMerchantOnboarding(String uid, String city) async {
    final onboardingResult = await _userRepository.isMerchantOnboardingCompleted(uid);
    
    await onboardingResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (onboardingCompleted) async {
        state = LoginFlowSuccess(
          uid: uid,
          role: UserRole.merchant,
          city: city,
          onboardingCompleted: onboardingCompleted ?? false,
        );
      },
    );
  }

  /// Update city after user selection
  Future<void> updateCity(String uid, String city) async {
    state = const LoginFlowLoading();
    
    final updateResult = await _userRepository.updateUserCity(
      uid: uid,
      city: city,
    );
    
    await updateResult.fold(
      (failure) async {
        state = LoginFlowError(failure);
      },
      (_) async {
        // City updated - continue with role check
        await _handleRoleCheck(uid, city);
      },
    );
  }

  /// Select role for multi-role user
  Future<void> selectRole(String uid, UserRole selectedRole, String city) async {
    if (selectedRole == UserRole.merchant) {
      // Check onboarding for merchant
      await _handleMerchantOnboarding(uid, city);
    } else {
      // Client - complete flow
      state = LoginFlowSuccess(
        uid: uid,
        role: UserRole.client,
        city: city,
        onboardingCompleted: true,
      );
    }
  }

  /// Reset to initial state
  void reset() {
    state = const LoginFlowInitial();
  }
}

