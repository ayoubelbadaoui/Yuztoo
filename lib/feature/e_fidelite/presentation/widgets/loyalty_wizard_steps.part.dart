part of 'loyalty_configuration_wizard.dart';

// ─── Step 0 — Activation ─────────────────────────────────────────────────────

class _ActivationStep extends StatelessWidget {
  const _ActivationStep({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Souhaitez-vous activer un programme de fidélité ?',
      subtitle:
          'Une fois activé, vos clients verront vos récompenses sur votre page vitrine.',
      child: Column(
        children: [
          _BigChoiceCard(
            icon: Icons.loyalty_rounded,
            title: 'Oui, activer',
            description:
                'Vos clients cumulent des récompenses après chaque passage validé.',
            selected: enabled,
            onTap: () => onChanged(true),
          ),
          const SizedBox(height: 10),
          _BigChoiceCard(
            icon: Icons.pause_circle_outline_rounded,
            title: 'Non, pas maintenant',
            description:
                'Vous pourrez activer le programme à tout moment depuis ces réglages.',
            selected: !enabled,
            onTap: () => onChanged(false),
            muted: true,
          ),
        ],
      ),
    );
  }
}

// ─── Step 1 — Trigger type ────────────────────────────────────────────────────

class _TriggerStep extends StatelessWidget {
  const _TriggerStep({
    required this.value,
    required this.onChanged,
  });

  final LoyaltyTriggerType value;
  final ValueChanged<LoyaltyTriggerType> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Comment déclencher la récompense ?',
      subtitle:
          'Choisissez ce que vos clients doivent accomplir pour mériter leur récompense.',
      child: Column(
        children: [
          _BigChoiceCard(
            icon: Icons.how_to_reg_outlined,
            title: 'Nombre de passages',
            description:
                'La récompense est débloquée après un certain nombre de visites validées.',
            selected: value == LoyaltyTriggerType.visitCount,
            onTap: () => onChanged(LoyaltyTriggerType.visitCount),
          ),
          const SizedBox(height: 10),
          _BigChoiceCard(
            icon: Icons.account_balance_wallet_outlined,
            title: "Cumul d'achats",
            description:
                'La récompense est débloquée après un montant total dépensé sur plusieurs achats.',
            selected: value == LoyaltyTriggerType.purchaseTotal,
            onTap: () => onChanged(LoyaltyTriggerType.purchaseTotal),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2 — Threshold ───────────────────────────────────────────────────────

class _ThresholdStep extends StatelessWidget {
  const _ThresholdStep({
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      return _StepSection(
        question: 'Combien de passages ?',
        subtitle:
            'Sélectionnez le nombre de visites validées avant le déclenchement de la récompense.',
        child: _ValueChipPicker<int>(
          value: config.visitsRequired,
          items: const [3, 5, 7, 10, 15, 20],
          labelBuilder: (v) => '$v',
          unit: 'passages',
          onChanged: notifier.setVisitsRequired,
        ),
      );
    }
    return _StepSection(
      question: 'Quel montant cumulé ?',
      subtitle:
          "Sélectionnez le total d'achats à atteindre avant le déclenchement de la récompense.",
      child: _ValueChipPicker<double>(
        value: _nearest(
          config.cumulativeSpendRequiredEuros,
          const [30, 50, 75, 100, 150, 200, 300, 500],
        ),
        items: const [30, 50, 75, 100, 150, 200, 300, 500],
        labelBuilder: (v) => '${v.toInt()} €',
        onChanged: notifier.setCumulativeSpendRequiredEuros,
      ),
    );
  }
}

// ─── Step 4 — Conditions ──────────────────────────────────────────────────────

class _ConditionsStep extends StatelessWidget {
  const _ConditionsStep({
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Conditions supplémentaires',
      subtitle:
          'Ces réglages optionnels affinent votre programme pour mieux correspondre à votre activité.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConditionCard(
            icon: Icons.price_check_outlined,
            title: 'Montant minimum par passage',
            value: config.minimumPerVisitEnabled,
            onChanged: notifier.setMinimumPerVisitEnabled,
            expandedChild: _DropdownCard<double>(
              value: _nearest(
                config.minimumPerVisitEuros ?? 50,
                const [10, 20, 30, 50, 75, 100],
              ),
              items: const [10, 20, 30, 50, 75, 100],
              labelBuilder: (v) => '${v.toInt()} € minimum',
              onChanged: (v) => notifier.setMinimumPerVisitEuros(v),
            ),
          ),
          const SizedBox(height: 12),
          _ConditionCard(
            icon: Icons.timer_outlined,
            title: 'Durée de validité de la récompense',
            value: config.rewardValidityEnabled,
            onChanged: notifier.setRewardValidityEnabled,
            expandedChild: _DropdownCard<int>(
              value: _nearest(
                config.rewardValidityDays ?? 30,
                const [7, 14, 30, 60, 90, 365],
              ),
              items: const [7, 14, 30, 60, 90, 365],
              labelBuilder: (v) => '$v jours',
              onChanged: (v) => notifier.setRewardValidityDays(v),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 5 — Validation ─────────────────────────────────────────────────────

class _ValidationStep extends StatelessWidget {
  const _ValidationStep({
    required this.value,
    required this.onChanged,
  });

  final LoyaltyPassageValidation value;
  final ValueChanged<LoyaltyPassageValidation> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Comment valider les passages ?',
      subtitle:
          'Le client demande un passage après le scan ; vous validez le montant (si besoin) dans Rappels ou via BLE.',
      child: Column(
        children: [
          _BigChoiceCard(
            icon: Icons.bluetooth_searching,
            title: 'Automatique',
            description:
                'Validation plus rapide en boutique (BLE) : le client demande toujours un passage, vous confirmez en un geste.',
            selected: value == LoyaltyPassageValidation.automatic,
            onTap: () => onChanged(LoyaltyPassageValidation.automatic),
          ),
          const SizedBox(height: 10),
          _BigChoiceCard(
            icon: Icons.pending_actions_rounded,
            title: 'Manuelle',
            description:
                'Chaque demande de passage est validée depuis l’écran Rappels (montant inclus pour les programmes à cumul €).',
            selected: value == LoyaltyPassageValidation.manual,
            onTap: () => onChanged(LoyaltyPassageValidation.manual),
          ),
        ],
      ),
    );
  }
}

// ─── Step 6 — Options ────────────────────────────────────────────────────────

class _ClientAmountStep extends StatelessWidget {
  const _ClientAmountStep({
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (!config.programEnabled) {
      return _StepSection(
        question: 'Récapitulatif',
        child: _DisabledProgramSummary(),
      );
    }

    final forced = config.clientMustEnterPurchaseAmount;

    return _StepSection(
      question: 'Saisie du montant par le client',
      subtitle: forced
          ? null
          : 'Optionnel — utile si vous souhaitez garder un historique des achats de vos clients.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConditionCard(
            icon: Icons.calculate_outlined,
            title: "Demander le montant de l'achat",
            value: forced || config.optionalAskClientPurchaseAmount,
            onChanged:
                forced ? (_) {} : notifier.setOptionalAskClientPurchaseAmount,
            disabled: forced,
            expandedChild: forced
                ? Text(
                    "Requis avec votre configuration (cumul d'achats ou points fidélité).",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textLightGrey,
                      height: 1.45,
                    ),
                  )
                : Text(
                    'Le client saisira le montant de chaque achat lors du scan.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textLightGrey,
                      height: 1.45,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Disabled program summary ─────────────────────────────────────────────────
//
// Shown on the last step when the merchant chose not to activate the program.
// Provides a friendly recap and a nudge to confirm with Enregistrer.

class _DisabledProgramSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MerchantColors.gold.withValues(alpha: 0.2)),
        color: MerchantColors.bgHeader.withValues(alpha: 0.4),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: MerchantColors.textLightGrey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.loyalty_outlined,
              color: MerchantColors.textLightGrey,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Programme désactivé',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Aucune récompense ne sera proposée à vos clients.\nVous pourrez activer le programme à tout moment.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textLightGrey,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: MerchantColors.gold.withValues(alpha: 0.08),
              border:
                  Border.all(color: MerchantColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded,
                    color: MerchantColors.gold, size: 15),
                const SizedBox(width: 8),
                Text(
                  "Appuyez sur « Enregistrer » pour confirmer.",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MerchantColors.gold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
