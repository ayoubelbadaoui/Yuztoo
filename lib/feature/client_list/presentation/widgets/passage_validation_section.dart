import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../loyalty/application/active_validation_providers.dart';
import '../../../loyalty/domain/entities/active_validation_request.dart';
import '../../../loyalty/presentation/active_validation_ui.dart';
import '../../../loyalty/presentation/widgets/merchant_passage_debug_simulate_sheet.dart';
import '../../../merchant/application/providers.dart' as merchant_providers;
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';

/// Live queue of client passage requests on **Vos clients** (not Rappels).
class PassageValidationSection extends ConsumerWidget {
  const PassageValidationSection({
    super.key,
    this.onOpenLoyaltySettings,
  });

  final VoidCallback? onOpenLoyaltySettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final merchant = merchantAsync.valueOrNull;
    if (merchant == null || !merchant.loyaltyEnabled) {
      return const SizedBox.shrink();
    }

    final config = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
    if (!config.programEnabled) return const SizedBox.shrink();

    final queueAsync = ref.watch(merchantActiveValidationQueueProvider);
    final awaiting = queueAsync.valueOrNull ?? const <ActiveValidationRequest>[];

    final isManual =
        config.passageValidation == LoyaltyPassageValidation.manual;
    final validatedMonth = merchant.rappelsMonthlyValidatedPassages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: MerchantColors.bgHeader.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.how_to_reg_outlined,
                      color: MerchantColors.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Validation des passages',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isMerchantPassageDebugEnabled)
                    IconButton(
                      tooltip: 'Simuler demande client (debug)',
                      onPressed: () => showMerchantPassageDebugSimulateSheet(
                        context,
                        merchant: merchant,
                      ),
                      icon: Icon(Icons.bug_report_outlined,
                          color: Colors.orange.shade300, size: 20),
                    ),
                  if (onOpenLoyaltySettings != null)
                    IconButton(
                      tooltip: 'Programme E-Fidélité',
                      onPressed: onOpenLoyaltySettings,
                      icon: const Icon(Icons.tune_rounded,
                          color: MerchantColors.textGrey, size: 20),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatChip(
                    label: 'En attente',
                    value: '${awaiting.length}',
                    highlight: awaiting.isNotEmpty,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Validés ce mois',
                    value: '$validatedMonth',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      label: 'Mode',
                      value: isManual ? 'Manuel' : 'Auto (BLE)',
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (isManual && awaiting.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'Les demandes apparaissent ici en direct quand un client valide '
                  'son scan sur votre vitrine. Vous recevez aussi une alerte instantanée.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    height: 1.45,
                    color: MerchantColors.textLightGrey,
                  ),
                ),
              )
            else if (!isManual)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'Validation automatique : utilisez « Valider un passage » (BLE) '
                  'quand le client est sur place.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    height: 1.45,
                    color: MerchantColors.textLightGrey,
                  ),
                ),
              )
            else
              ...awaiting.map(
                (session) => _AwaitingPassageTile(
                  session: session,
                  merchant: merchant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? MerchantColors.gold.withValues(alpha: 0.15)
            : MerchantColors.navyCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? MerchantColors.gold.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: MerchantColors.textGrey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: compact ? 13 : 16,
              fontWeight: FontWeight.w700,
              color: highlight ? MerchantColors.gold : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AwaitingPassageTile extends StatelessWidget {
  const _AwaitingPassageTile({
    required this.session,
    required this.merchant,
  });

  final ActiveValidationRequest session;
  final Merchant merchant;

  @override
  Widget build(BuildContext context) {
    final needsSpend = session.programSnapshot.triggerType ==
            LoyaltyTriggerType.purchaseTotal ||
        session.programSnapshot.rewardKind == LoyaltyRewardKind.loyaltyPoints;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showMerchantActiveValidationSheet(
          context: context,
          merchant: merchant,
          session: session,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: MerchantColors.gold.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: MerchantColors.gold.withValues(alpha: 0.2),
                backgroundImage: session.clientPhotoUrl != null &&
                        session.clientPhotoUrl!.isNotEmpty
                    ? NetworkImage(session.clientPhotoUrl!)
                    : null,
                child: session.clientPhotoUrl == null ||
                        session.clientPhotoUrl!.isEmpty
                    ? Text(
                        session.clientDisplayName.isNotEmpty
                            ? session.clientDisplayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: MerchantColors.gold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.clientDisplayName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      needsSpend
                          ? 'Montant à saisir par vous'
                          : 'Passage à confirmer',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MerchantColors.textLightGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Valider',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.bgHeader,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
