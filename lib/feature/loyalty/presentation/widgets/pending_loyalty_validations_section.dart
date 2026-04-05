import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../application/providers.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../../rappels/application/widgets.dart';
import '../../application/client_loyalty_providers.dart' as client_loyalty_providers;
import '../../domain/entities/loyalty_pending_client_row.dart';

part 'pending_loyalty_validations_section.part.dart';

/// Liste des clients avec passage(s) en attente — affiché dans Rappels si validation manuelle.
class PendingLoyaltyValidationsSection extends ConsumerStatefulWidget {
  const PendingLoyaltyValidationsSection({super.key, required this.merchant});

  final Merchant merchant;

  @override
  ConsumerState<PendingLoyaltyValidationsSection> createState() =>
      _PendingLoyaltyValidationsSectionState();
}

class _PendingLoyaltyValidationsSectionState
    extends ConsumerState<PendingLoyaltyValidationsSection> {
  String? _busyClientUid;

  LoyaltyProgramConfig get _config =>
      widget.merchant.loyaltyProgram ??
      LoyaltyProgramConfig.fallbackFromFlags(
        loyaltyEnabled: widget.merchant.loyaltyEnabled,
      );

  bool get _visible =>
      widget.merchant.loyaltyEnabled &&
      _config.programEnabled &&
      _config.passageValidation == LoyaltyPassageValidation.manual;

  static String _shortClientLabel(String uid) {
    if (uid.length <= 8) return uid;
    return '…${uid.substring(uid.length - 8)}';
  }

  Future<double?> _promptSpendAmount(BuildContext context) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => _buildSpendPromptDialog(ctx, controller),
    );
    controller.dispose();
    return amount;
  }

  Future<void> _onValidateOne(LoyaltyPendingClientRow row) async {
    final auth = ref.read(authStateProvider);
    if (auth is! Authenticated) return;
    if (auth.user.id != widget.merchant.ownerUid) return;

    double? spend;
    if (_config.triggerType != LoyaltyTriggerType.visitCount) {
      if (!mounted) return;
      spend = await _promptSpendAmount(context);
      if (spend == null) return;
    }

    setState(() => _busyClientUid = row.clientUid);
    final useCase =
        ref.read(client_loyalty_providers.validatePendingLoyaltyPassageProvider);
    final result = await useCase.call(
      actingOwnerUid: auth.user.id,
      merchant: widget.merchant,
      clientUid: row.clientUid,
      declaredSpendEuros: spend,
    );
    if (!mounted) return;
    setState(() => _busyClientUid = null);

    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Passage validé pour ${_shortClientLabel(row.clientUid)}',
              style: GoogleFonts.outfit(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    final pendingAsync = ref.watch(
      client_loyalty_providers.pendingLoyaltyClientsForMerchantProvider(
        widget.merchant.id,
      ),
    );

    return _buildPendingLoyaltyBody(context, pendingAsync);
  }
}
