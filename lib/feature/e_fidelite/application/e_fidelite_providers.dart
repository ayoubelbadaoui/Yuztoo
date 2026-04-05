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
