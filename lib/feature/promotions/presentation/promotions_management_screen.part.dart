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
        systemNavigationBarColor: MerchantColors.bgHeader,
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
                      data: (promotions) => SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).padding.bottom + 80,
                        ),
                        child: Column(
                          children: [
                            _buildAddPromoSection(),
                            if (promotions.isEmpty)
                              _buildEmpty()
                            else
                              _buildPromoList(promotions),
                            const PromoAnalytics(),
                            _buildNotificationsAutoButton(),
                          ],
                        ),
                      ),
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
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: MerchantColors.gold, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: MerchantColors.gold,
                        size: 15,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
              const SizedBox(width: 12),
              Text(
                'Promotions',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
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
                width: 2,
                strokeAlign: BorderSide.strokeAlignCenter,
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
                    child: Icon(Icons.add,
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

  // ── Promo list ────────────────────────────────────────────────────────────

  Widget _buildPromoList(List<Promotion> promotions) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          ...promotions.asMap().entries.map((entry) {
            final index = entry.key;
            final promo = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PromoCard(
                promo: promo,
                onToggle: (v) => _onToggle(promo, v),
                onDelete: () => _confirmDelete(promo),
                onPickImage: () => _pickImageForPromo(index, promotions),
              ),
            );
          }),
          Text(
            'Créez et publiez des promotions pour vos clients mais aussi pour la communauté Yuztoo locale',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Notifications auto button ────────────────────────────────────────────

  Widget _buildNotificationsAutoButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GestureDetector(
        onTap: () => widget.onNavigate?.call('notifications-auto'),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MerchantColors.gold.withValues(alpha: 0.5),
              width: 2,
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
                  child: Icon(Icons.notifications_active_outlined,
                      color: MerchantColors.darkOverlay, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notifications automatiques',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: MerchantColors.gold, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
