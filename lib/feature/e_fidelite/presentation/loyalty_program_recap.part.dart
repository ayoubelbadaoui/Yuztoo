part of 'e_fidelite_screen.dart';

class LoyaltyProgramRecap extends ConsumerWidget {
  const LoyaltyProgramRecap({
    super.key,
    required this.config,
    required this.onEdit,
    required this.onDisable,
    this.saving = false,
  });

  final LoyaltyProgramConfig config;
  final void Function({required int initialStep}) onEdit;
  final VoidCallback onDisable;
  final bool saving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = config.programEnabled;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isActive) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.2),
                ),
                color: MerchantColors.bgHeader.withValues(alpha: 0.4),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.pause_circle_outline_rounded,
                    color: MerchantColors.textLightGrey,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Programme désactivé',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos clients ne voient plus d’offre fidélité sur votre vitrine. '
                    'Réactivez ou modifiez le programme ci-dessous.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: MerchantColors.textLightGrey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Votre programme',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MerchantColors.gold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          _RecapRow(label: 'Statut', value: config.recapStatusLabel),
          _RecapRow(
            label: 'Déclencheur',
            value: config.triggerType == LoyaltyTriggerType.visitCount
                ? '${config.recapTriggerLabel}'
                : config.recapTriggerLabel,
          ),
          _RecapRow(label: 'Récompense', value: config.recapRewardLabel),
          _RecapRow(label: 'Validation', value: config.recapValidationLabel),
          if (config.recapValidityLabel != null)
            _RecapRow(label: 'Validité', value: config.recapValidityLabel!),
          if (config.recapMinimumLabel != null)
            _RecapRow(label: 'Minimum', value: config.recapMinimumLabel!),
          if (config.recapClientAmountLabel != null)
            _RecapRow(
              label: 'Montant client',
              value: config.recapClientAmountLabel!,
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: MerchantColors.bgHeader.withValues(alpha: 0.55),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              config.clientSummaryText,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _RecapActionButton(
            label: isActive ? 'Modifier le programme' : 'Réactiver / modifier',
            icon: Icons.edit_outlined,
            primary: true,
            onTap: saving
                ? null
                : () => onEdit(initialStep: isActive ? 1 : 0),
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            _RecapActionButton(
              label: saving ? 'En cours…' : 'Désactiver',
              icon: Icons.pause_circle_outline_rounded,
              primary: false,
              onTap: saving ? null : onDisable,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapActionButton extends StatelessWidget {
  const _RecapActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: primary && onTap != null
                ? const LinearGradient(
                    colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                  )
                : null,
            color: primary
                ? (onTap == null
                    ? MerchantColors.gold.withValues(alpha: 0.35)
                    : null)
                : Colors.transparent,
            border: primary
                ? null
                : Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.65),
                    width: 1.5,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: primary
                    ? MerchantColors.darkOverlay
                    : MerchantColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primary
                      ? MerchantColors.darkOverlay
                      : MerchantColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
