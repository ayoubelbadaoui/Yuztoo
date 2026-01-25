import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/user_repository.dart';
import 'state/user_profile_state.dart';

/// Controller for managing user profile state in memory
/// Fetches and caches user profile data (roles, city, onboarding status)
class UserProfileController extends StateNotifier<AsyncValue<UserProfileState?>> {
  UserProfileController({
    required UserRepository userRepository,
  })  : _userRepository = userRepository,
        super(const AsyncValue.data(null));

  final UserRepository _userRepository;

  /// Fetch and cache user profile from Firestore
  /// Called once on successful login
  Future<void> fetchProfile(String uid) async {
    state = const AsyncValue.loading();

    // Fetch roles
    final rolesResult = await _userRepository.getUserRoles(uid);
    
    rolesResult.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (rolesMap) async {
        if (rolesMap == null) {
          state = const AsyncValue.data(null);
          return;
        }

        // Fetch city
        final cityResult = await _userRepository.getUserCity(uid);
        
        cityResult.fold(
          (failure) {
            state = AsyncValue.error(failure, StackTrace.current);
          },
          (city) async {
            // Fetch onboarding status if merchant
            bool? onboardingCompleted;
            if (rolesMap['merchant'] == true) {
              final onboardingResult = await _userRepository.isMerchantOnboardingCompleted(uid);
              onboardingCompleted = onboardingResult.fold(
                (_) => null,
                (completed) => completed,
              );
            }

            // Get email from auth user (we'll need to pass it or fetch it)
            // For now, we'll create state with available data
            state = AsyncValue.data(
              UserProfileState(
                uid: uid,
                email: '', // Will be set from auth user
                roles: rolesMap,
                city: city,
                onboardingCompleted: onboardingCompleted,
              ),
            );
          },
        );
      },
    );
  }

  /// Update profile with email and phone from auth user
  void updateFromAuthUser({
    required String email,
    String? phone,
  }) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(
        currentState.copyWith(
          email: email,
          phone: phone,
        ),
      );
    }
  }

  /// Update city in profile state
  void updateCity(String city) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(
        currentState.copyWith(city: city),
      );
    }
  }

  /// Clear profile state (on logout)
  void clear() {
    state = const AsyncValue.data(null);
  }
}

