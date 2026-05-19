import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import 'loyalty_program_editing_notifier.dart';
import 'use_cases/update_merchant_loyalty_program.dart';

final loyaltyProgramEditingProvider =
    StateNotifierProvider<LoyaltyProgramEditingNotifier, LoyaltyProgramConfig>(
  (ref) => LoyaltyProgramEditingNotifier(),
);

final updateMerchantLoyaltyProgramProvider =
    Provider<UpdateMerchantLoyaltyProgram>((ref) {
  final repository = ref.watch(merchantRepositoryProvider);
  return UpdateMerchantLoyaltyProgram(repository);
});

/// Set when Paramètres Fidélité ON is deferred until E-Fidélité save.
final pendingLoyaltyConfigurationProvider = StateProvider<bool>((ref) => false);

/// Highest wizard step index reached in the current configuration session.
final loyaltyWizardMaxStepVisitedProvider = StateProvider<int>((ref) => 0);
