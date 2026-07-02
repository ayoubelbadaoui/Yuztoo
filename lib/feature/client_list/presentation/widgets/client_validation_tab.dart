import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/shared/widgets/yuztoo_pull_refresh.dart';
import '../../../loyalty/application/active_validation_providers.dart';
import '../../../merchant/application/providers.dart' as merchant_providers;
import '../../../merchant/domain/entities/client_gratification_config.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../../merchant/presentation/merchant_ble_scan_screen.dart';
import 'passage_validation_section.dart';

/// **Vos clients → Validation** — queue, mode, gratification, BLE.
class ClientValidationTab extends ConsumerWidget {
  const ClientValidationTab({
    super.key,
    this.onNavigate,
  });

  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);

    return merchantAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MerchantColors.gold),
      ),
      error: (_, __) => _message(
        'Impossible de charger votre commerce.',
      ),
      data: (merchant) {
        if (merchant == null) {
          return _message('Connectez-vous avec un compte commerçant.');
        }
        if (!merchant.loyaltyEnabled) {
          return _loyaltyDisabled(context, merchant);
        }
        final config = merchant.loyaltyProgram ??
            LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
        if (!config.programEnabled) {
          return _loyaltyDisabled(context, merchant);
        }
        return _buildContent(context, ref, merchant, config);
      },
    );
  }

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: MerchantColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _loyaltyDisabled(BuildContext context, Merchant merchant) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.loyalty_outlined,
                size: 48, color: MerchantColors.gold.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Activez E-Fidélité pour gérer la validation des passages, '
              'les paliers clients et le mode automatique ou manuel.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: MerchantColors.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (onNavigate != null)
              _HubLinkButton(
                label: 'Configurer E-Fidélité',
                icon: Icons.card_giftcard_outlined,
                onTap: () => onNavigate!.call('e-fidelite'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Merchant merchant,
    LoyaltyProgramConfig config,
  ) {
    final grat = merchant.effectiveGratificationConfig;
    final isManual =
        config.passageValidation == LoyaltyPassageValidation.manual;

    return YuztooPullRefresh(
      onRefresh: () async {
        ref.invalidate(merchant_providers.currentMerchantForOwnerProvider);
        ref.invalidate(merchantActiveValidationQueueProvider);
        await ref
            .read(merchant_providers.currentMerchantForOwnerProvider.future)
            .catchError((_) => null);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PassageValidationSection(),
            const SizedBox(height: 12),
            _HubCard(
              icon: Icons.tune_rounded,
              title: 'Mode de validation',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModeBadge(isManual: isManual),
                  const SizedBox(height: 12),
                  Text(
                    isManual
                        ? 'Le client demande un passage après le scan sur votre vitrine. '
                            'Vous validez ici ou via l\'alerte instantanée (montant saisi par vous si besoin).'
                        : 'Validation rapide en boutique via BLE : le client demande un passage, '
                            'vous confirmez avec le bouton « Valider un passage ».',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      height: 1.45,
                      color: MerchantColors.textLightGrey,
                    ),
                  ),
                  if (config.effectiveAskClientPurchaseAmount) ...[
                    const SizedBox(height: 10),
                    _InfoPill(
                      icon: Icons.euro_rounded,
                      text: config.clientMustEnterPurchaseAmount
                          ? 'Montant d\'achat requis à chaque passage (cumul € ou points).'
                          : 'Montant d\'achat optionnel demandé au client.',
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (onNavigate != null)
                    _HubLinkButton(
                      label: 'Modifier dans E-Fidélité',
                      icon: Icons.open_in_new_rounded,
                      onTap: () => onNavigate!.call('e-fidelite'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _HubCard(
              icon: Icons.star_outline_rounded,
              title: 'Paliers & gratification client',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GratificationSummary(config: grat),
                  const SizedBox(height: 14),
                  if (onNavigate != null)
                    _HubLinkButton(
                      label: 'Paramétrer les paliers',
                      icon: Icons.settings_outlined,
                      onTap: () => onNavigate!.call('gratification-config'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _HubCard(
              icon: Icons.nfc_rounded,
              title: 'Valider en boutique',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isManual
                        ? 'En mode manuel, utilisez cette action pour valider un passage '
                            'lorsque le client est devant vous (sans attendre sa demande).'
                        : 'Détectez un client à proximité (BLE) et validez son passage en un geste.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      height: 1.45,
                      color: MerchantColors.textLightGrey,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              MerchantBleScanScreen(merchant: merchant),
                          fullscreenDialog: true,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MerchantColors.gold,
                        foregroundColor: MerchantColors.bgMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.nfc_rounded, size: 20),
                      label: Text(
                        'Valider un passage (BLE)',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: MerchantColors.bgHeader.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: MerchantColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.isManual});

  final bool isManual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MerchantColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MerchantColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isManual
                ? Icons.pending_actions_rounded
                : Icons.bluetooth_searching,
            color: MerchantColors.gold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            isManual ? 'Validation manuelle' : 'Validation automatique (BLE)',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: MerchantColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GratificationSummary extends StatelessWidget {
  const _GratificationSummary({required this.config});

  final ClientGratificationConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryRow(
          label: config.nouveauLabel,
          value: '0 – ${config.habituelThreshold - 1} passages',
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: config.habituelLabel,
          value:
              '${config.habituelThreshold} – ${config.vipThreshold - 1} passages',
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: config.vipLabel,
          value: '≥ ${config.vipThreshold} passages',
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Inactif après',
          value: '${config.inactifAfterDays} jours sans visite',
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Niveau visible client',
          value: config.showTierToClient ? 'Oui' : 'Non',
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textWhite,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: MerchantColors.textGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 11,
                height: 1.4,
                color: MerchantColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubLinkButton extends StatelessWidget {
  const _HubLinkButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MerchantColors.navyCard.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: MerchantColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: MerchantColors.textGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
