part of 'loyalty_cards_screen.dart';

// ─── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications});

  final VoidCallback onNotifications;

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
    final merchantCount = entries.length;

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
        if (merchantCount > 0)
          Text(
            '$merchantCount commerce${merchantCount > 1 ? 's' : ''} suivi${merchantCount > 1 ? 's' : ''}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
            ),
          )
        else
          Text(
            'Scannez votre premier commerce pour commencer',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
            ),
          ),
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

    final card = progressAsync.when(
      loading: () => _buildCard(
        context,
        fraction: 0.0,
        label: '— passages',
        rewardAvailable: false,
        tier: null,
      ),
      error: (_, __) => _buildCard(
        context,
        fraction: 0.0,
        label: 'Erreur',
        rewardAvailable: false,
        tier: null,
      ),
      data: (progress) => _buildCard(
        context,
        fraction: entry.progressFraction(progress),
        label: entry.progressLabel(progress),
        rewardAvailable: entry.isRewardAvailable(progress),
        tier: ClientLoyaltyTier.fromPassages(progress.validatedPassages),
      ),
    );

    if (onStoreTap == null) return card;
    return GestureDetector(
      onTap: () => onStoreTap!(entry.merchantId),
      child: card,
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required double fraction,
    required String label,
    required bool rewardAvailable,
    required ClientLoyaltyTier? tier,
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
          // Merchant name + reward badge
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
