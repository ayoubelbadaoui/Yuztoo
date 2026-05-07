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
                child: Text(
                  'Fidélité',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                ),
              ),
              // Dual-profile: quick switch back to merchant shell
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
                        Icons.switch_account,
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
  });

  final String firstName;
  final AsyncValue<List<ClientLoyaltyEntry>> feedAsync;

  @override
  Widget build(BuildContext context) {
    final entries = feedAsync.valueOrNull ?? [];
    // Own merchant (isOwnMerchant=true) is not a "followed" merchant.
    final followedCount = entries.where((e) => !e.isOwnMerchant).length;
    final hasOwnMerchant = entries.any((e) => e.isOwnMerchant);
    final totalCount = entries.length;

    String subtitle;
    if (totalCount == 0) {
      subtitle = 'Scannez votre premier commerce pour commencer';
    } else if (followedCount == 0 && hasOwnMerchant) {
      subtitle = 'Votre commerce est actif — suivez d\'autres commerces pour cumuler des avantages';
    } else if (followedCount > 0) {
      subtitle =
          '$followedCount commerce${followedCount > 1 ? 's' : ''} suivi${followedCount > 1 ? 's' : ''}';
    } else {
      subtitle = 'Scannez votre premier commerce pour commencer';
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
        if (totalCount > 0) ...[
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

// ─── Feed (loading / empty / list) ────────────────────────────────────────────

class _LoyaltyFeed extends StatelessWidget {
  const _LoyaltyFeed({required this.feedAsync, this.onStoreTap});

  final AsyncValue<List<ClientLoyaltyEntry>> feedAsync;
  final ValueChanged<String>? onStoreTap;

  @override
  Widget build(BuildContext context) {
    return feedAsync.when(
      loading: () => const _LoadingCards(),
      error: (_, __) => const _EmptyState(
        message:
            'Impossible de charger votre fidélité pour le moment.',
      ),
      data: (entries) {
        if (entries.isEmpty) return const _EmptyState();
        return Column(
          children: [
            for (final entry in entries) ...[
              _MerchantLoyaltyCard(entry: entry, onStoreTap: onStoreTap),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
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
                    AppLogo(
                      size: 100,
                      fallback: Icon(
                        Icons.location_on_rounded,
                        size: 56,
                        color: MerchantColors.gold.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'yuztoo',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.gold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'pour eux, pour vous',
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
        showWelcomeBadge: false,
        welcomeGiftText: '',
      ),
      error: (_, __) => _buildCard(
        context,
        fraction: 0.0,
        label: 'Erreur',
        rewardAvailable: false,
        tier: null,
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
          showWelcomeBadge:
              progress.hasFirstVisit && welcomeGift.isNotEmpty,
          welcomeGiftText: welcomeGift,
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
      child: card,
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
    required bool showWelcomeBadge,
    String welcomeGiftText = '',
  }) {
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
              if (!rewardAvailable && tier != null)
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
                    tier.label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _tierColor(tier),
                    ),
                  ),
                ),
            ],
          ),

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
