part of 'loyalty_cards_screen.dart';

// ─── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.onNotifications,
    this.onSwitchToMerchant,
  });

  final VoidCallback onNotifications;
  final VoidCallback? onSwitchToMerchant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderStronger),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: const YuztooGradientTitle('Fidélité'),
              ),
              // Dual-profile: storefront icon (not person/account silhouette)
              if (onSwitchToMerchant != null)
                GestureDetector(
                  onTap: onSwitchToMerchant,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MerchantColors.gold
                            .withValues(alpha: MerchantColors.goldBorderAlpha),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.storefront_outlined,
                        color: MerchantColors.gold,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              if (onSwitchToMerchant != null) const SizedBox(width: 8),
              GestureDetector(
                onTap: onNotifications,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: MerchantColors.gold,
                      size: 24,
                    ),
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

// ─── Greeting block ─────────────────────────────────────────────────────────

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({
    required this.firstName,
    required this.feedAsync,
    required this.followedCountAsync,
  });

  final String firstName;
  final AsyncValue<List<ClientLoyaltyEntry>> feedAsync;
  final AsyncValue<List<String>> followedCountAsync;

  @override
  Widget build(BuildContext context) {
    // Production: count every followed commerce, not only loyalty-program cards.
    final followedCount = followedCountAsync.valueOrNull?.length ??
        (feedAsync.valueOrNull?.length ?? 0);

    String subtitle;
    if (followedCount == 0) {
      subtitle = 'Scannez votre premier commerce pour commencer';
    } else {
      subtitle =
          '$followedCount commerce${followedCount > 1 ? 's' : ''} suivi${followedCount > 1 ? 's' : ''}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFD4A017)],
            stops: [0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            'Bonjour $firstName 👋',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textGrey,
          ),
        ),
        if (followedCount > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Récompense prête : repérez « Dispo ! » sur une carte, puis '
            'touchez-la pour afficher votre bon.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: MerchantColors.textGrey,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Four-type filter (real rewardKind from Firestore programs) ───────────────

bool _rewardMatchesCategory(ClientRewardItem r, LoyaltyRewardCategory c) {
  final kind = r.rewardKind ??
      r.merchant.loyaltyProgram?.rewardKind ??
      LoyaltyRewardKind.purchaseVoucher;
  return loyaltyRewardCategoryFromKind(kind) == c;
}

IconData _categoryIcon(LoyaltyRewardCategory c) {
  switch (c) {
    case LoyaltyRewardCategory.purchaseVoucher:
      return Icons.card_giftcard_rounded;
    case LoyaltyRewardCategory.discountPercent:
      return Icons.percent_rounded;
    case LoyaltyRewardCategory.freeProduct:
      return Icons.redeem_rounded;
    case LoyaltyRewardCategory.loyaltyPoints:
      return Icons.stars_rounded;
  }
}

class _LoyaltyCategoryFilterBar extends StatelessWidget {
  const _LoyaltyCategoryFilterBar({
    required this.selected,
    required this.feedCounts,
    required this.rewardCounts,
    required this.onSelected,
  });

  final LoyaltyRewardCategory selected;
  final Map<LoyaltyRewardCategory, int> feedCounts;
  final Map<LoyaltyRewardCategory, int> rewardCounts;
  final ValueChanged<LoyaltyRewardCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de fidélité',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MerchantColors.textLightGrey,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in kLoyaltyRewardCategories) ...[
                _CategoryChip(
                  category: c,
                  label: c.labelFr,
                  icon: _categoryIcon(c),
                  programCount: feedCounts[c] ?? 0,
                  rewardCount: rewardCounts[c] ?? 0,
                  selected: selected == c,
                  onTap: () => onSelected(c),
                ),
                if (c != LoyaltyRewardCategory.loyaltyPoints)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.label,
    required this.icon,
    required this.programCount,
    required this.rewardCount,
    required this.selected,
    required this.onTap,
  });

  final LoyaltyRewardCategory category;
  final String label;
  final IconData icon;
  final int programCount;
  final int rewardCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 124,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? MerchantColors.gold
              : MerchantColors.gold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? MerchantColors.gold
                : MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? MerchantColors.darkOverlay
                  : MerchantColors.gold,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: selected
                    ? MerchantColors.darkOverlay
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              programCount == 0
                  ? category.notSubscribedHintFr
                  : rewardCount > 0
                      ? '$programCount commerce${programCount > 1 ? 's' : ''} · '
                          '$rewardCount bon${rewardCount > 1 ? 's' : ''}'
                      : '$programCount commerce${programCount > 1 ? 's' : ''}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 9,
                height: 1.25,
                color: selected
                    ? MerchantColors.darkOverlay.withValues(alpha: 0.8)
                    : programCount == 0
                        ? MerchantColors.textGrey
                        : MerchantColors.textLightGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feed (loading / empty / list) ────────────────────────────────────────────

class _LoyaltyFeed extends StatelessWidget {
  const _LoyaltyFeed({
    required this.category,
    required this.feedAsync,
    this.onStoreTap,
  });

  /// Active filter, or null when the screen renders an unfiltered view
  /// (representedCategoryCount < 2 — see `LoyaltyCardsScreen.build`).
  final LoyaltyRewardCategory? category;
  final AsyncValue<List<ClientLoyaltyEntry>> feedAsync;
  final ValueChanged<String>? onStoreTap;

  @override
  Widget build(BuildContext context) {
    return feedAsync.when(
      loading: () => const _LoadingCards(),
      error: (_, __) => const _EmptyState(
        message: 'Impossible de charger votre fidélité pour le moment.',
      ),
      data: (entries) {
        final cat = category;
        final visible = cat == null
            ? entries.toList()
            : entries.where((e) => cat.matchesConfig(e.config)).toList();
        final categoryLabel = cat?.labelFr;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes cartes fidélité',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _feedSubtitle(visible.length, categoryLabel),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
              ),
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              _LoyaltyTypeEmptyCard(
                category: cat,
                forRewards: false,
              )
            else
              for (final entry in visible) ...[
                _MerchantLoyaltyCard(
                  entry: entry,
                  onStoreTap: onStoreTap,
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }

  String _feedSubtitle(int count, String? categoryLabel) {
    final plural = count > 1 ? 's' : '';
    if (categoryLabel == null) {
      if (count == 0) return 'Aucune carte de fidélité';
      return '$count carte$plural de fidélité';
    }
    if (count == 0) return 'Programmes « $categoryLabel »';
    return '$count carte$plural « $categoryLabel »';
  }
}

/// Friendly empty placeholder when the client has no program/bon in a type.
class _LoyaltyTypeEmptyCard extends StatelessWidget {
  const _LoyaltyTypeEmptyCard({
    required this.category,
    required this.forRewards,
  });

  /// Null when the carnet is rendered without a category filter — the
  /// copy collapses to a category-agnostic message in that case.
  final LoyaltyRewardCategory? category;
  final bool forRewards;

  @override
  Widget build(BuildContext context) {
    final cat = category;
    final title = forRewards
        ? 'Aucun bon pour l’instant'
        : 'Pas encore inscrit';
    final body = _buildBody(cat, forRewards);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.gold.withValues(alpha: 0.1),
            ),
            child: Icon(
              cat == null
                  ? Icons.card_giftcard_rounded
                  : _categoryIcon(cat),
              color: MerchantColors.gold.withValues(alpha: 0.55),
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textLightGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static String _buildBody(LoyaltyRewardCategory? cat, bool forRewards) {
    if (cat == null) {
      return forRewards
          ? 'Vous n’avez pas encore de bon. '
              'Continuez à cumuler chez vos commerces inscrits.'
          : 'Vous ne suivez pas encore de commerce avec un programme '
              'de fidélité. Scannez le QR d’une vitrine pour vous '
              'inscrire et commencer à cumuler.';
    }
    return forRewards
        ? 'Vous n’avez pas encore de bon « ${cat.labelFr} ». '
            'Continuez à cumuler chez vos commerces inscrits.'
        : 'Vous ne suivez pas encore de commerce avec un programme '
            '« ${cat.labelFr} ». Scannez le QR d’une vitrine pour '
            'vous inscrire et commencer à cumuler.';
  }
}

// ─── "Mes avantages" — bons filtrés par type de programme ─────────────────────

class _MesAvantagesShell extends StatelessWidget {
  const _MesAvantagesShell({
    required this.category,
    required this.child,
    this.rewardCount,
  });

  /// Null when the carnet is rendered without a category filter.
  final LoyaltyRewardCategory? category;
  final Widget child;
  final int? rewardCount;

  @override
  Widget build(BuildContext context) {
    final count = rewardCount;
    final cat = category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes avantages',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _subtitle(count, cat),
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: MerchantColors.textGrey,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  static String _subtitle(int? count, LoyaltyRewardCategory? cat) {
    if (cat == null) {
      if (count == null) return 'Bons disponibles';
      if (count == 0) return 'Pas encore de bon';
      final plural = count > 1 ? 's' : '';
      return '$count bon$plural disponible$plural';
    }
    if (count == null) return 'Bons « ${cat.labelFr} »';
    if (count == 0) return 'Pas encore de bon « ${cat.labelFr} »';
    final plural = count > 1 ? 's' : '';
    return '$count bon$plural disponible$plural';
  }
}

class _MesAvantagesSection extends ConsumerWidget {
  const _MesAvantagesSection({required this.category});

  /// Null when the carnet is rendered without a category filter.
  final LoyaltyRewardCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(availableClientRewardsProvider);
    final cat = category;
    return rewardsAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _MesAvantagesShell(
          category: cat,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MerchantColors.gold,
                ),
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _MesAvantagesShell(
          category: cat,
          child: _LoyaltyTypeEmptyCard(
            category: cat,
            forRewards: true,
          ),
        ),
      ),
      data: (rewards) {
        final active = cat == null
            ? rewards.toList()
            : rewards.where((r) => _rewardMatchesCategory(r, cat)).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _MesAvantagesShell(
            category: cat,
            rewardCount: active.length,
            child: active.isEmpty
                ? _LoyaltyTypeEmptyCard(
                    category: cat,
                    forRewards: true,
                  )
                : Column(
                    children: [
                      for (var i = 0; i < active.length; i++) ...[
                        _RewardCard(reward: active[i]),
                        if (i < active.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward});

  final ClientRewardItem reward;

  @override
  Widget build(BuildContext context) {
    final merchantName = reward.merchant.displayName?.isNotEmpty == true
        ? reward.merchant.displayName!
        : reward.merchant.name;
    final isWelcome = reward.kind == ClientRewardKind.welcome;
    final now = DateTime.now();
    final daysLeft = reward.daysLeftAt(now);
    final isExpiringSoon = reward.isExpiringSoonAt(now);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: MerchantColors.navyCard,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _RewardDetailSheet(reward: reward),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            // Expiring-soon outranks welcome highlight: an evergreen
            // welcome bon is less urgent than a milestone that expires
            // tomorrow. Amber border telegraphs urgency without leaving
            // the gold/navy palette.
            color: isExpiringSoon
                ? const Color(0xFFE8A93C)
                : MerchantColors.gold
                    .withValues(alpha: isWelcome ? 0.55 : 0.30),
            width: isExpiringSoon ? 1.5 : (isWelcome ? 1.5 : 1),
          ),
          boxShadow: isWelcome
              ? [
                  BoxShadow(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.bgMain,
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.5),
                ),
              ),
              child: ClipOval(
                child: reward.merchant.logoUrl != null &&
                        reward.merchant.logoUrl!.isNotEmpty
                    ? Image.network(
                        reward.merchant.logoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          isWelcome
                              ? Icons.card_giftcard_rounded
                              : Icons.local_offer_rounded,
                          color: MerchantColors.gold,
                          size: 20,
                        ),
                      )
                    : Icon(
                        isWelcome
                            ? Icons.card_giftcard_rounded
                            : Icons.local_offer_rounded,
                        color: MerchantColors.gold,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reward.title,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: MerchantColors.gold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Expiry badge takes precedence over the welcome
                      // badge — losing a bon to expiration is the more
                      // urgent message to surface.
                      if (isExpiringSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8A93C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            daysLeft == 0
                                ? 'Expire aujourd\'hui'
                                : (daysLeft == 1
                                    ? 'Expire demain'
                                    : 'J-${daysLeft ?? 0}'),
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: MerchantColors.darkOverlay,
                            ),
                          ),
                        )
                      else if (isWelcome)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MerchantColors.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'À utiliser',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: MerchantColors.darkOverlay,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    merchantName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reward.description,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: MerchantColors.textLightGrey,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: MerchantColors.gold,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardDetailSheet extends ConsumerStatefulWidget {
  const _RewardDetailSheet({required this.reward});

  final ClientRewardItem reward;

  @override
  ConsumerState<_RewardDetailSheet> createState() =>
      _RewardDetailSheetState();
}

class _RewardDetailSheetState extends ConsumerState<_RewardDetailSheet> {
  bool _busy = false;

  Future<void> _confirmAndClaim() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.bgMain,
        title: Text(
          'Utiliser ce bon ?',
          style: GoogleFonts.outfit(
            color: MerchantColors.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Présentez votre téléphone au commerçant. Une fois confirmé, '
          'le bon sera marqué comme utilisé et ne pourra plus être '
          'présenté.',
          style: GoogleFonts.outfit(
            color: MerchantColors.textLightGrey,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(color: MerchantColors.textLightGrey),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: MerchantColors.gold,
              foregroundColor: MerchantColors.darkOverlay,
            ),
            child: Text(
              'Utiliser',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    final auth = ref.read(authStateProvider);
    if (auth is! Authenticated) {
      setState(() => _busy = false);
      return;
    }
    final useCase = ref.read(claimWelcomeBonProvider);
    final result = await useCase.call(
      clientUid: auth.user.id,
      merchant: widget.reward.merchant,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) {
        // Invalidate the aggregator so the bon disappears from "Mes
        // avantages" immediately. The per-merchant progress stream picks
        // up `welcome_bon_claimed_at` on its own.
        ref.invalidate(availableClientRewardsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bon utilisé — bonne dégustation 🎁',
              style: merchantSnackBarTextOnGold(),
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
    final reward = widget.reward;
    final merchantName = reward.merchant.displayName?.isNotEmpty == true
        ? reward.merchant.displayName!
        : reward.merchant.name;
    final isWelcome = reward.kind == ClientRewardKind.welcome;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: MerchantColors.textLightGrey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Icon(
              isWelcome
                  ? Icons.card_giftcard_rounded
                  : Icons.local_offer_rounded,
              color: MerchantColors.gold,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              reward.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              merchantName,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MerchantColors.bgMain,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                reward.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.5,
                  color: MerchantColors.textWhite,
                ),
              ),
            ),
            if (reward.validUntilAt != null) ...[
              const SizedBox(height: 12),
              _ExpiryLine(validUntilAt: reward.validUntilAt!),
            ],
            const SizedBox(height: 14),
            Text(
              isWelcome
                  ? 'Présentez votre téléphone au commerçant pour récupérer '
                      'votre cadeau de bienvenue.'
                  : 'Le commerçant validera votre bon depuis son application '
                      'lors de votre prochain passage en boutique.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            if (reward.actionable)
              FilledButton(
                onPressed: _busy ? null : _confirmAndClaim,
                style: FilledButton.styleFrom(
                  backgroundColor: MerchantColors.gold,
                  foregroundColor: MerchantColors.darkOverlay,
                  disabledBackgroundColor:
                      MerchantColors.gold.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MerchantColors.darkOverlay,
                        ),
                      )
                    : Text(
                        'Utiliser le bon',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              )
            else
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MerchantColors.gold,
                  side: const BorderSide(color: MerchantColors.gold),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Compris',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Expiry line shown inside the reward detail sheet. Renders day-count
/// + absolute date in French. Amber when ≤3 days left so the urgency
/// matches the card-level badge.
class _ExpiryLine extends StatelessWidget {
  const _ExpiryLine({required this.validUntilAt});

  final DateTime validUntilAt;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diffDays = validUntilAt.difference(now).inDays;
    final isExpiringSoon = diffDays >= 0 && diffDays <= 3;
    final color = isExpiringSoon
        ? const Color(0xFFE8A93C)
        : MerchantColors.textLightGrey;
    final headline = diffDays < 0
        ? 'Bon expiré'
        : diffDays == 0
            ? 'Expire aujourd\'hui'
            : diffDays == 1
                ? 'Expire demain'
                : 'Expire dans $diffDays jours';
    final formatted =
        '${validUntilAt.day.toString().padLeft(2, '0')}/'
        '${validUntilAt.month.toString().padLeft(2, '0')}/'
        '${validUntilAt.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isExpiringSoon
              ? Icons.warning_amber_rounded
              : Icons.schedule_rounded,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$headline · $formatted',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Loading shimmer cards ──────────────────────────────────────────────────

class _LoadingCards extends StatefulWidget {
  const _LoadingCards();

  @override
  State<_LoadingCards> createState() => _LoadingCardsState();
}

class _LoadingCardsState extends State<_LoadingCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmerOpacity = 0.35 + _anim.value * 0.25;
        return Column(
          children: List.generate(
            2,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Opacity(
                opacity: 1.0 - i * 0.25,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: MerchantColors.navyCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MerchantColors.gold
                          .withValues(alpha: shimmerOpacity * 0.4),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MerchantColors.gold
                              .withValues(alpha: shimmerOpacity * 0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 12,
                              width: 120,
                              decoration: BoxDecoration(
                                color: MerchantColors.gold
                                    .withValues(alpha: shimmerOpacity * 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: MerchantColors.gold
                                    .withValues(alpha: shimmerOpacity * 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.outfit(
      fontSize: 15,
      height: 1.5,
      color: MerchantColors.textLightGrey,
    );
    final gold = base.copyWith(
      color: MerchantColors.gold,
      fontWeight: FontWeight.w700,
    );

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AspectRatio(
              aspectRatio: 0.72,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MerchantColors.bgHeader,
                      MerchantColors.bgMain.withValues(alpha: 0.95),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard_rounded,
                      size: 56,
                      color: MerchantColors.gold.withValues(alpha: 0.85),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mes avantages',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.gold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vos bons apparaîtront ici',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: MerchantColors.textLightGrey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            style: base,
            children: [
              TextSpan(
                  text: message ??
                      'Aucun avantage enregistré pour le moment sur votre carte fidélité '),
              if (message == null) TextSpan(text: 'Yuztoo', style: gold),
              if (message == null) const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Vos passages chez un commerçant partenaire s\'afficheront ici après une visite.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.5,
            color: MerchantColors.textLightGrey,
          ),
        ),
      ],
    );
  }
}

// ─── Per-merchant loyalty card ────────────────────────────────────────────────

class _MerchantLoyaltyCard extends ConsumerWidget {
  const _MerchantLoyaltyCard({required this.entry, this.onStoreTap});

  final ClientLoyaltyEntry entry;
  final ValueChanged<String>? onStoreTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync =
        ref.watch(clientLoyaltyProgressForMerchantProvider(entry.merchantId));

    bool rewardAvailable = false;

    final card = progressAsync.when(
      loading: () => _buildCard(
        context,
        fraction: 0.0,
        label: '— passages',
        rewardAvailable: false,
        tier: null,
        validatedPassages: 0,
        showWelcomeBadge: false,
        welcomeGiftText: '',
      ),
      error: (_, __) => _buildCard(
        context,
        fraction: 0.0,
        label: 'Erreur',
        rewardAvailable: false,
        tier: null,
        validatedPassages: 0,
        showWelcomeBadge: false,
        welcomeGiftText: '',
      ),
      data: (progress) {
        rewardAvailable = entry.isRewardAvailable(progress);
        final welcomeGift =
            entry.merchant.welcomeGiftDescription?.trim() ?? '';
        return _buildCard(
          context,
          fraction: entry.progressFraction(progress),
          label: entry.progressLabel(progress),
          rewardAvailable: rewardAvailable,
          tier: ClientLoyaltyTier.fromPassages(progress.validatedPassages),
          validatedPassages: progress.validatedPassages,
          showWelcomeBadge:
              progress.hasFirstVisit && welcomeGift.isNotEmpty,
          welcomeGiftText: welcomeGift,
          programEnded: entry.programEnded,
        );
      },
    );

    return GestureDetector(
      onTap: () {
        if (rewardAvailable) {
          _showRewardBottomSheet(context);
        } else {
          onStoreTap?.call(entry.merchantId);
        }
      },
      child: Column(
        children: [
          card,
          ClientValidationBanner(merchantId: entry.merchantId),
        ],
      ),
    );
  }

  void _showRewardBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: MerchantColors.gold,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Votre bon est disponible !',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              entry.merchantName,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: MerchantColors.gold,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MerchantColors.bgHeader,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    entry.rewardLabel(),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Présentez ce bon à ${entry.merchantName} lors de votre prochaine visite. Le commerçant validera l\'utilisation de votre récompense.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.55,
                color: MerchantColors.textLightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: MerchantColors.gold,
                  foregroundColor: MerchantColors.darkOverlay,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Fermer',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required double fraction,
    required String label,
    required bool rewardAvailable,
    required ClientLoyaltyTier? tier,
    required int validatedPassages,
    required bool showWelcomeBadge,
    String welcomeGiftText = '',
    bool programEnded = false,
  }) {
    final gratConfig = entry.merchant.effectiveGratificationConfig;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rewardAvailable
              ? MerchantColors.gold
              : MerchantColors.gold.withValues(alpha: 0.25),
          width: rewardAvailable ? 1.5 : 1,
        ),
        boxShadow: [
          if (rewardAvailable)
            BoxShadow(
              color: MerchantColors.gold.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merchant name + reward / tier badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.bgMain,
                  border: Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.5)),
                ),
                child: ClipOval(
                  child: entry.logoUrl != null && entry.logoUrl!.isNotEmpty
                      ? Image.network(
                          entry.logoUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront_outlined,
                            color: MerchantColors.gold,
                            size: 18,
                          ),
                        )
                      : const Icon(
                          Icons.storefront_outlined,
                          color: MerchantColors.gold,
                          size: 18,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.merchantName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (rewardAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MerchantColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Dispo !',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.darkOverlay,
                    ),
                  ),
                ),
              if (!rewardAvailable &&
                  tier != null &&
                  gratConfig.showTierToClient)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _tierColor(tier).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _tierColor(tier).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    gratConfig.labelForPassages(validatedPassages),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _tierColor(tier),
                    ),
                  ),
                ),
            ],
          ),

          if (programEnded) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: MerchantColors.textGrey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: MerchantColors.textGrey.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'Programme terminé — vos avantages obtenus restent valides',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: MerchantColors.textLightGrey,
                  height: 1.35,
                ),
              ),
            ),
          ],

          // First-visit welcome bonus badge — shown when first_visit_at exists
          // in Firestore AND the merchant has a welcome gift description.
          if (showWelcomeBadge) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF9A825).withValues(alpha: 0.18),
                    const Color(0xFFE65100).withValues(alpha: 0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 5),
                  Text(
                    'Bon d’accueil (1re connexion)',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showWelcomeBadge && welcomeGiftText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              welcomeGiftText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
                height: 1.45,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor:
                  MerchantColors.gold.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  MerchantColors.gold),
            ),
          ),
          const SizedBox(height: 8),

          // Progress label + reward label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textGrey,
                ),
              ),
              Text(
                entry.rewardLabel(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: MerchantColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _tierColor(ClientLoyaltyTier tier) {
  switch (tier) {
    case ClientLoyaltyTier.nouveau:
      return MerchantColors.textGrey;
    case ClientLoyaltyTier.soutien:
      return const Color(0xFF4FC3F7);
    case ClientLoyaltyTier.habitue:
      return MerchantColors.gold;
    case ClientLoyaltyTier.vip:
      return const Color(0xFFE040FB);
  }
}
