part of 'promotions_management_screen.dart';

extension _PromotionsManagementScreenUi on _PromotionsManagementScreenState {
  Widget _buildPromotionsScaffold(
    BuildContext context,
    AsyncValue<List<Promotion>> promotionsAsync,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack?.call();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: promotionsAsync.when(
                      loading: _buildLoading,
                      error: (err, _) => _buildError(err),
                    data: (promotions) {
                        final now = DateTime.now();
                        final active = promotions
                            .where((p) =>
                                p.isOnline && p.dateTo.isAfter(now))
                            .toList();
                        final others = promotions
                            .where((p) =>
                                !p.isOnline || !p.dateTo.isAfter(now))
                            .toList();
                        return RefreshIndicator(
                          color: MerchantColors.gold,
                          backgroundColor: MerchantColors.navyCard,
                          onRefresh: _onRefresh,
                          child: SingleChildScrollView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom +
                                  80,
                            ),
                            child: Column(
                              children: [
                                _buildAddPromoSection(),
                                if (promotions.isEmpty)
                                  _buildEmpty()
                                else ...[
                                  _buildActiveSection(active),
                                  if (others.isNotEmpty)
                                    _buildOthersSection(others),
                                  PromoAnalytics(promotions: promotions),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // ── Full-screen overlay while image is uploading ──
              if (_isUpdatingImage)
                Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 22),
                      decoration: BoxDecoration(
                        color: MerchantColors.navyCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: MerchantColors.gold
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: MerchantColors.gold,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Mise à jour de l\'image…',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: MerchantColors.textLightGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Creating indicator ──
              if (_isCreating)
                Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 22),
                      decoration: BoxDecoration(
                        color: MerchantColors.navyCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: MerchantColors.gold
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: MerchantColors.gold,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Création en cours…',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: MerchantColors.textLightGrey,
                            ),
                          ),
                        ],
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

  // ── Header with back button ──────────────────────────────────────────────

  Widget _buildHeader() {
    final promotions =
        ref.watch(merchantPromotionsProvider).valueOrNull ?? [];
    final activeCount = promotions
        .where((p) => p.isOnline && p.dateTo.isAfter(DateTime.now()))
        .length;

    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (widget.onBack != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onBack,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold,
                      size: 20,
                    ),
                  ),
                )
              else
                const SizedBox(width: 44),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Promotions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: MerchantColors.gold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeCount',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MerchantColors.bgHeader,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shimmer loading ──────────────────────────────────────────────────────

  Widget _buildLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Add promo skeleton
          _shimmerBox(height: 68, borderRadius: 12),
          const SizedBox(height: 24),
          // Promo card skeletons
          ...List.generate(
            2,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _shimmerBox(height: 180, borderRadius: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, double borderRadius = 8}) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => Container(
        height: height,
        decoration: BoxDecoration(
          color: MerchantColors.navyCard.withValues(alpha: _shimmerAnim.value),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────

  Widget _buildError(Object err) {
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
                color: Colors.redAccent.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.cloud_off_outlined,
                  color: Colors.redAccent, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les promotions',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion et réessayez.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.invalidate(merchantPromotionsProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: MerchantColors.gold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.bgHeader,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.gold.withValues(alpha: 0.1),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                color: MerchantColors.gold,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune promotion active',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première promotion pour attirer vos clients et booster votre activité.',
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
    );
  }

  // ── Add promo CTA ────────────────────────────────────────────────────────

  Widget _buildAddPromoSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: _isCreating ? null : _showAddPromoSheet,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: _isCreating ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: MerchantColors.navyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: MerchantColors.gold,
                  ),
                  child: const Center(
                    child: Icon(Icons.add_rounded,
                        color: MerchantColors.darkOverlay, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ajoutez une promotion',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Active promos section ─────────────────────────────────────────────────

  static const _kPreviewCount = 3;

  Widget _buildActiveSection(List<Promotion> active) {
    if (active.isEmpty) return const SizedBox.shrink();

    final displayed = _showAllActive
        ? active
        : active.take(_kPreviewCount).toList();
    final hidden = active.length - _kPreviewCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Actives',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.textLightGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${active.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4ADE80),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cards
          ...displayed.asMap().entries.map((entry) {
            final index = entry.key;
            final promo = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PromoCard(
                promo: promo,
                onToggle: (v) => _onToggle(promo, v),
                onDelete: () => _confirmDelete(promo),
                onPickImage: () =>
                    _pickImageForPromo(index, active),
              ),
            );
          }),
          // Voir plus / Voir moins
          if (active.length > _kPreviewCount) ...[
            GestureDetector(
              onTap: () => _rebuild(() => _showAllActive = !_showAllActive),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: MerchantColors.navyCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: MerchantColors.gold
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAllActive
                          ? 'Voir moins'
                          : 'Voir les $hidden autre${hidden > 1 ? 's' : ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.gold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _showAllActive
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: MerchantColors.gold,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Expired / offline section ─────────────────────────────────────────────

  Widget _buildOthersSection(List<Promotion> others) {
    final displayed = _showAllExpired
        ? others
        : others.take(_kPreviewCount).toList();
    final hidden = others.length - _kPreviewCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle header — collapsed by default
          GestureDetector(
            onTap: () =>
                _rebuild(() => _showAllExpired = !_showAllExpired),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: MerchantColors.textGrey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Expirées / Hors ligne',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.textLightGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: MerchantColors.textGrey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${others.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showAllExpired
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: MerchantColors.textGrey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          // Cards (only when expanded)
          if (_showAllExpired) ...[
            ...displayed.asMap().entries.map((entry) {
              final index = entry.key;
              final promo = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PromoCard(
                  promo: promo,
                  onToggle: (v) => _onToggle(promo, v),
                  onDelete: () => _confirmDelete(promo),
                  onPickImage: () =>
                      _pickImageForPromo(index, others),
                ),
              );
            }),
            if (others.length > _kPreviewCount)
              GestureDetector(
                onTap: () => _rebuild(
                    () => _showAllExpired = !_showAllExpired),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: MerchantColors.navyCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAllExpired && displayed.length > _kPreviewCount
                            ? 'Voir moins'
                            : 'Voir les $hidden autre${hidden > 1 ? 's' : ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.gold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _showAllExpired
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: MerchantColors.gold,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

}
