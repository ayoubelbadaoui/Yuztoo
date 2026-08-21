part of 'discovery_screen.dart';

extension _DiscoveryScreenUi on _DiscoveryScreenState {
  Widget _buildHeader(BuildContext context) {
    final typeFilter = ref.watch(discoveryMerchantTypeFilterProvider);
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold.withValues(
                  alpha: MerchantColors.goldBorderStronger,
                ),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: YuztooGradientTitle('Découvrir'),
                    ),
                    IconButton(
                      onPressed: widget.onNotifications,
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: MerchantColors.gold,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Tab chips — always visible
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _typeChip(
                        label: 'Proche de moi',
                        icon: Icons.location_on_rounded,
                        value: 'proche',
                        current: typeFilter,
                        onTap: () {
                          ref
                              .read(discoveryMerchantTypeFilterProvider.notifier)
                              .state = 'proche';
                          ref.invalidate(discoveryCityMerchantsProvider);
                        },
                      ),
                      const SizedBox(width: 8),
                      _typeChip(
                        label: 'Recommandés',
                        icon: Icons.star_rounded,
                        value: 'recommandes',
                        current: typeFilter,
                        onTap: () {
                          ref
                              .read(discoveryMerchantTypeFilterProvider.notifier)
                              .state = 'recommandes';
                          ref.invalidate(discoveryRecommendedMerchantsProvider);
                          ref.invalidate(discoveryFollowedMerchantsProvider);
                        },
                      ),
                      const SizedBox(width: 8),
                      _typeChip(
                        label: 'Associations',
                        icon: Icons.groups_rounded,
                        value: 'associations',
                        current: typeFilter,
                        onTap: () {
                          ref
                              .read(discoveryMerchantTypeFilterProvider.notifier)
                              .state = 'associations';
                          ref.invalidate(discoveryCityMerchantsProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required IconData icon,
    required String value,
    required String current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? MerchantColors.gold
              : MerchantColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? MerchantColors.gold
                : MerchantColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? MerchantColors.bgHeader
                  : MerchantColors.textGrey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? MerchantColors.bgHeader
                    : MerchantColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(discoveryCityMerchantsProvider);
    ref.invalidate(discoveryRecommendedMerchantsProvider);
    ref.invalidate(discoveryFollowedMerchantsProvider);
    ref.invalidate(discoveryMerchantsProvider);
    await ref.read(discoveryMerchantsProvider.future);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchQueryChanged,
        style: GoogleFonts.outfit(fontSize: 14, color: MerchantColors.textWhite),
        cursorColor: MerchantColors.gold,
        decoration: InputDecoration(
          hintText: 'Rechercher un commerce…',
          hintStyle: GoogleFonts.outfit(
              fontSize: 14, color: MerchantColors.textGrey),
          prefixIcon: const Icon(Icons.search_rounded,
              color: MerchantColors.gold, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchQueryChanged('');
                  },
                  child: const Icon(Icons.close_rounded,
                      color: MerchantColors.textGrey, size: 18),
                )
              : null,
          filled: true,
          fillColor: MerchantColors.inputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: MerchantColors.gold.withValues(alpha: 0.18)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: MerchantColors.gold, width: 1.1),
          ),
        ),
      ),
    );
  }

  // ── Live search results ─────────────────────────────────────────────────

  Widget _buildSearchResults(BuildContext context, Set<String> followedIds) {
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        Expanded(
          child: YuztooPullRefresh(
            onRefresh: _onRefresh,
            child: _buildSearchBody(followedIds),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBody(Set<String> followedIds) {
    if (_searchLoading) {
      return yuztooRefreshableEmpty(
        const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                color: MerchantColors.gold, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return yuztooRefreshableEmpty(
        Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.search_off_rounded,
                    color: MerchantColors.gold, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                'Aucun commerce trouvé',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Essayez un autre nom ou vérifiez l\'orthographe.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = _searchResults[i];
        final id = m['id'] as String;
        final isFollowed = followedIds.contains(id);
        return _SearchResultCard(
          merchant: m,
          isFollowed: isFollowed,
          onTap: () => widget.onStoreSelect(id),
        );
      },
    );
  }

  // ── Tab content ─────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    List<Merchant> merchants,
    Set<String> viewedIds,
    Set<String> followedIds,
  ) {
    final typeFilter = ref.watch(discoveryMerchantTypeFilterProvider);

    if (merchants.isEmpty) {
      return Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: YuztooPullRefresh(
              onRefresh: _onRefresh,
              child: yuztooRefreshableEmpty(
                _buildEmptyState(context, typeFilter, followedIds),
              ),
            ),
          ),
        ],
      );
    }

    return YuztooPullRefresh(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildSectionLabel(context, typeFilter),
            _buildBusinessGrid(context, merchants, viewedIds, followedIds),
            _buildInviteButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String typeFilter) {
    final label = switch (typeFilter) {
      'recommandes' => 'Recommandés par les commerces que vous suivez',
      'associations' => 'Associations & artistes près de vous',
      _ => 'Dans votre région',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: MerchantColors.textGrey,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildRecommandesEmptyState(
    BuildContext context,
    Set<String> followedIds,
  ) {
    final hasFollowed = followedIds.isNotEmpty;

    return YuztooPullRefresh(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.gold.withValues(alpha: 0.08),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                color: MerchantColors.gold,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFollowed
                  ? 'Pas encore de recommandations'
                  : 'Suivez des commerces',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFollowed
                  ? 'Quand un commerce que vous suivez recommande un partenaire sur sa vitrine, le partenaire apparaît ici — pas le commerce que vous suivez déjà.'
                  : 'Les commerces que vous suivez recommandent ici leurs partenaires de confiance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textGrey,
                height: 1.45,
              ),
            ),
            if (hasFollowed) ...[
              const SizedBox(height: 16),
              Text(
                'Vos commerces suivis restent dans « Proche de moi » et dans votre carnet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textGrey,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                ref.read(discoveryMerchantTypeFilterProvider.notifier).state =
                    'proche';
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: MerchantColors.gold,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Voir Proche de moi',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String typeFilter,
    Set<String> followedIds,
  ) {
    if (typeFilter == 'recommandes') {
      return _buildRecommandesEmptyState(context, followedIds);
    }

    final isAssociations = typeFilter == 'associations';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.gold.withValues(alpha: 0.08),
                border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.25)),
              ),
              child: Icon(
                isAssociations
                    ? Icons.groups_outlined
                    : Icons.storefront_outlined,
                color: MerchantColors.gold,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAssociations
                  ? 'Aucune association ou artiste pour le moment'
                  : 'Aucun commerce dans votre région',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAssociations
                  ? 'Revenez bientôt ou cherchez par nom / type.'
                  : 'Utilisez la recherche pour trouver un commerce par nom ou type.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textGrey,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage(double? height) {
    return Container(
      height: height,
      width: height != null ? double.infinity : null,
      color: MerchantColors.bgHeader,
      child: Center(
        child: Icon(
          Icons.storefront_outlined,
          size: height != null ? 32 : 24,
          color: MerchantColors.gold.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildBusinessGrid(
    BuildContext context,
    List<Merchant> merchants,
    Set<String> viewedIds,
    Set<String> followedIds,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemCount: merchants.length,
        itemBuilder: (context, index) {
          final m = merchants[index];
          return _BusinessGridCard(
            merchant: m,
            hasViewed: viewedIds.contains(m.id),
            isFollowing: followedIds.contains(m.id),
            onTap: () => widget.onStoreSelect(m.id),
            placeholderBuilder: () => _placeholderImage(null),
          );
        },
      ),
    );
  }

  Widget _buildInviteButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            SharePlus.instance.share(
              ShareParams(
                text:
                    '📍 Rejoins Yuztoo — l\'app qui connecte les commerçants locaux et leurs clients !\n\nhttps://yuztoo.web.app/invite',
                subject: 'Rejoins Yuztoo',
              ),
            );
          },
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFD4A017)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: MerchantColors.gold.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.share_rounded,
                      color: MerchantColors.bgHeader, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Invite un commerçant',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.bgHeader,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Search result card ───────────────────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.merchant,
    required this.isFollowed,
    required this.onTap,
  });

  final Map<String, dynamic> merchant;
  final bool isFollowed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = merchant['name'] as String? ?? '';
    final city = merchant['city'] as String? ?? '';
    final logoUrl = merchant['logoUrl'] as String?;
    final type = merchant['merchantType'] as String?;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Row(
          children: [
            // Logo or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                color: MerchantColors.gold.withValues(alpha: 0.1),
                child: logoUrl != null && logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.store_rounded,
                            color: MerchantColors.gold,
                            size: 20),
                      )
                    : const Icon(Icons.store_rounded,
                        color: MerchantColors.gold, size: 20),
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
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (type == 'b2b' || type == 'b2c') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                MerchantColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: MerchantColors.gold
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            type == 'b2b' ? 'B2B' : 'B2C',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: MerchantColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 10, color: MerchantColors.textGrey),
                        const SizedBox(width: 3),
                        Text(
                          city,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: MerchantColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isFollowed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Suivi',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.gold,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: MerchantColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Business grid card ───────────────────────────────────────────────────────

class _BusinessGridCard extends StatelessWidget {
  const _BusinessGridCard({
    required this.merchant,
    required this.hasViewed,
    required this.isFollowing,
    required this.onTap,
    required this.placeholderBuilder,
  });

  final Merchant merchant;
  final bool hasViewed;
  final bool isFollowing;
  final VoidCallback onTap;
  final Widget Function() placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    final name = merchant.displayName ?? merchant.name;
    final imageUrl = merchant.bannerUrl ?? merchant.logoUrl;
    final category = merchant.displayCategory;
    final isInactive = merchant.status != 'active';
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image / placeholder
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => placeholderBuilder(),
                  )
                : placeholderBuilder(),
            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // Followed / viewed / offline badges (top-right)
            if (isFollowing || hasViewed || isInactive)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isInactive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: MerchantColors.textGrey.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Text(
                          'Hors ligne',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: MerchantColors.textGrey,
                          ),
                        ),
                      ),
                    if (isInactive && isFollowing) const SizedBox(width: 4),
                    if (isFollowing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: MerchantColors.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Suivi',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: MerchantColors.bgHeader,
                          ),
                        ),
                      ),
                    if (isFollowing && hasViewed) const SizedBox(width: 4),
                    if (hasViewed)
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: MerchantColors.gold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Category pill (top-left)
            if (category != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // Merchant name bottom
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.textWhite,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
