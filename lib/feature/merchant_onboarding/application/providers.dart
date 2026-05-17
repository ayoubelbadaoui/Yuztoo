import 'package:flutter_riverpod/flutter_riverpod.dart';

export '../../auth/core/application/providers.dart'
    show
        authStateProvider,
        currentUserIdProvider,
        markMerchantOnboardingCompletedProvider;
export '../../auth/core/application/state/auth_state.dart'
    show AuthState, Authenticated;

/// Selected merchant category title from the acquisition onboarding wizard.
///
/// This is UI-only state, used to prefill the merchant profile form so we don't
/// ask the user twice.
final selectedMerchantCategoryTitleProvider = StateProvider<String?>((ref) => null);

/// Selected merchant category id (e.g. `restaurant`, `retail`). Stable across
/// title localization and used by [MerchantSubcategoryCatalog] to look up the
/// correct subcategory list. Both this and [selectedMerchantCategoryTitleProvider]
/// are set together when the category step completes.
final selectedMerchantCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Selected merchant subcategory title (optional).
final selectedMerchantSubcategoryTitleProvider =
    StateProvider<String?>((ref) => null);

