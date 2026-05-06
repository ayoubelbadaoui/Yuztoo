import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../application/client_loyalty_providers.dart' as loyalty_providers;
import '../../application/providers.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../../rappels/application/widgets.dart';
import '../../domain/entities/loyalty_pending_client_row.dart';

part 'reward_redemption_section.part.dart';

/// Merchant-facing section in Rappels showing clients who have an earned reward
/// ready to be given. The merchant taps "Donner le bon" which resets that
/// client's counter and starts a new loyalty cycle.
class RewardRedemptionSection extends ConsumerStatefulWidget {
  const RewardRedemptionSection({super.key, required this.merchant});

  final Merchant merchant;

  @override
  ConsumerState<RewardRedemptionSection> createState() =>
      _RewardRedemptionSectionState();
}

class _RewardRedemptionSectionState
    extends ConsumerState<RewardRedemptionSection> {
  String? _busyClientUid;

  LoyaltyProgramConfig get _config =>
      widget.merchant.loyaltyProgram ??
      LoyaltyProgramConfig.fallbackFromFlags(
        loyaltyEnabled: widget.merchant.loyaltyEnabled,
      );

  bool get _visible =>
      widget.merchant.loyaltyEnabled && _config.programEnabled;

  bool get _isSpendBased =>
      _config.triggerType == LoyaltyTriggerType.purchaseTotal;

  static String _shortLabel(String uid) {
    if (uid.length <= 8) return uid;
    return '…${uid.substring(uid.length - 8)}';
  }

  Future<void> _onMarkUsed(LoyaltyPendingClientRow row) async {
    final auth = ref.read(authStateProvider);
    if (auth is! Authenticated) return;
    if (auth.user.id != widget.merchant.ownerUid) return;

    setState(() => _busyClientUid = row.clientUid);
    final useCase = ref.read(loyalty_providers.redeemLoyaltyRewardProvider);
    final result = await useCase.call(
      actingOwnerUid: auth.user.id,
      merchant: widget.merchant,
      clientUid: row.clientUid,
    );
    if (!mounted) return;
    setState(() => _busyClientUid = null);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red[700],
        ),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Récompense accordée à ${_shortLabel(row.clientUid)} — nouveau cycle démarré !',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MerchantColors.gold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final rewardParams = (
      merchantId: widget.merchant.id,
      visitsRequired: _config.visitsRequired,
      spendRequired: _config.cumulativeSpendRequiredEuros,
      isSpendBased: _isSpendBased,
    );

    final rewardAsync = ref.watch(
      loyalty_providers.clientsWithRewardAvailableProvider(rewardParams),
    );

    return _buildRewardBody(context, rewardAsync);
  }
}
