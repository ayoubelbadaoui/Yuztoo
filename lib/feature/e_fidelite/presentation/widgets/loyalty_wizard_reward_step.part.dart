part of 'loyalty_configuration_wizard.dart';

// ─── Step 3 — Reward ─────────────────────────────────────────────────────────
//
// 2×2 card grid for reward-type selection + an animated config panel that
// slides in below, keyed on the selected kind so it cross-fades on type change.

class _RewardStep extends StatelessWidget {
  const _RewardStep({
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Quelle récompense souhaitez-vous offrir ?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1 ────────────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _RewardTypeCard(
                    icon: Icons.card_giftcard_outlined,
                    title: "Bon d'achat",
                    description: 'Valeur sur vos dépenses',
                    selected:
                        config.rewardKind == LoyaltyRewardKind.purchaseVoucher,
                    onTap: () =>
                        notifier.setRewardKind(LoyaltyRewardKind.purchaseVoucher),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RewardTypeCard(
                    icon: Icons.percent_rounded,
                    title: 'Remise',
                    description: 'Sur le prochain achat',
                    selected:
                        config.rewardKind == LoyaltyRewardKind.discountPercent,
                    onTap: () => notifier
                        .setRewardKind(LoyaltyRewardKind.discountPercent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Row 2 ────────────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _RewardTypeCard(
                    icon: Icons.restaurant_outlined,
                    title: 'Produit offert',
                    description: 'Un article de votre carte',
                    selected:
                        config.rewardKind == LoyaltyRewardKind.freeProduct,
                    onTap: () =>
                        notifier.setRewardKind(LoyaltyRewardKind.freeProduct),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RewardTypeCard(
                    icon: Icons.stars_rounded,
                    title: 'Points',
                    description: '1 € = X pts accumulés',
                    selected:
                        config.rewardKind == LoyaltyRewardKind.loyaltyPoints,
                    onTap: () => notifier
                        .setRewardKind(LoyaltyRewardKind.loyaltyPoints),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Animated config panel ─────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                axisAlignment: -1,
                child: child,
              ),
            ),
            child: _RewardConfigPanel(
              key: ValueKey(config.rewardKind),
              config: config,
              notifier: notifier,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reward type selection card ───────────────────────────────────────────────
//
// Compact card used in the 2×2 grid. Icon, title, description + animated gold
// border and checkmark when selected.

class _RewardTypeCard extends StatelessWidget {
  const _RewardTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? MerchantColors.gold.withValues(alpha: 0.1)
                : MerchantColors.bgHeader.withValues(alpha: 0.6),
            border: Border.all(
              color: selected
                  ? MerchantColors.gold
                  : MerchantColors.gold.withValues(alpha: 0.22),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: MerchantColors.gold.withValues(
                        alpha: selected ? 0.2 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: MerchantColors.gold, size: 19),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: MerchantColors.gold,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: MerchantColors.textLightGrey,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reward config panel ──────────────────────────────────────────────────────
//
// Framed container with a header row (tune icon + dynamic title) and the
// appropriate config sub-widget for the current reward kind.

class _RewardConfigPanel extends StatelessWidget {
  const _RewardConfigPanel({
    super.key,
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final (panelTitle, content) = switch (config.rewardKind) {
      LoyaltyRewardKind.purchaseVoucher => (
          "Configurer le bon d'achat",
          _VoucherConfig(config: config, notifier: notifier),
        ),
      LoyaltyRewardKind.discountPercent => (
          'Configurer la remise',
          _DiscountConfig(config: config, notifier: notifier),
        ),
      LoyaltyRewardKind.freeProduct => (
          'Configurer le produit offert',
          _FreeProductConfig(config: config, notifier: notifier),
        ),
      LoyaltyRewardKind.loyaltyPoints => (
          'Configurer les points',
          _LoyaltyPointsConfig(config: config, notifier: notifier),
        ),
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: MerchantColors.gold.withValues(alpha: 0.4)),
        color: MerchantColors.bgHeader.withValues(alpha: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.07),
              border: Border(
                bottom: BorderSide(
                  color: MerchantColors.gold.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded,
                    color: MerchantColors.gold, size: 15),
                const SizedBox(width: 8),
                Text(
                  panelTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }
}

// ─── Voucher config ───────────────────────────────────────────────────────────

class _VoucherConfig extends StatelessWidget {
  const _VoucherConfig({required this.config, required this.notifier});

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Type de bon',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MerchantColors.textLightGrey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SegmentButton(
                label: 'Pourcentage',
                icon: Icons.percent_rounded,
                selected: config.purchaseVoucherUsesPercent,
                onTap: () => notifier.setPurchaseVoucherUsesPercent(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SegmentButton(
                label: 'Montant fixe',
                icon: Icons.euro_rounded,
                selected: !config.purchaseVoucherUsesPercent,
                onTap: () => notifier.setPurchaseVoucherUsesPercent(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Valeur du bon',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MerchantColors.textLightGrey,
          ),
        ),
        const SizedBox(height: 8),
        _DropdownCard<double>(
          value: _nearest(
            config.purchaseVoucherValue,
            config.purchaseVoucherUsesPercent
                ? const [5, 10, 15, 20, 25]
                : const [5, 10, 15, 20, 25, 50],
          ),
          items: config.purchaseVoucherUsesPercent
              ? const [5, 10, 15, 20, 25]
              : const [5, 10, 15, 20, 25, 50],
          labelBuilder: (v) =>
              config.purchaseVoucherUsesPercent ? '$v %' : '$v €',
          onChanged: notifier.setPurchaseVoucherValue,
        ),
      ],
    );
  }
}

// ─── Discount config ──────────────────────────────────────────────────────────

class _DiscountConfig extends StatelessWidget {
  const _DiscountConfig({required this.config, required this.notifier});

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pourcentage de remise',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MerchantColors.textLightGrey,
          ),
        ),
        const SizedBox(height: 8),
        _DropdownCard<double>(
          value: _nearest(config.discountNextPurchasePercent,
              const [5, 10, 15, 20, 25, 30]),
          items: const [5, 10, 15, 20, 25, 30],
          labelBuilder: (v) => '$v %',
          onChanged: notifier.setDiscountNextPurchasePercent,
        ),
      ],
    );
  }
}

// ─── Free product config ──────────────────────────────────────────────────────

class _FreeProductConfig extends StatelessWidget {
  const _FreeProductConfig({required this.config, required this.notifier});

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Nommez le produit tel qu'il apparaît sur votre carte (ex. café, dessert du jour, pizza…).",
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: MerchantColors.textLightGrey,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        _FreeProductNameField(
          initialText: config.freeProductSummaryLabel ?? '',
          onChanged: notifier.setFreeProductSummaryLabel,
        ),
      ],
    );
  }
}

// ─── Loyalty points config ────────────────────────────────────────────────────

class _LoyaltyPointsConfig extends StatelessWidget {
  const _LoyaltyPointsConfig({required this.config, required this.notifier});

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Points gagnés par euro dépensé',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MerchantColors.textLightGrey,
          ),
        ),
        const SizedBox(height: 8),
        _DropdownCard<double>(
          value: _nearest(config.pointsPerEuro, const [0.5, 1, 2, 5, 10]),
          items: const [0.5, 1, 2, 5, 10],
          labelBuilder: (v) => '$v pt / €',
          onChanged: notifier.setPointsPerEuro,
        ),
      ],
    );
  }
}
