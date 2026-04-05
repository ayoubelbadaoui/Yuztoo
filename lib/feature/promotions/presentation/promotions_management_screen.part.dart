part of 'promotions_management_screen.dart';

extension _PromotionsManagementScreenUi on _PromotionsManagementScreenState {
  Widget _buildPromotionsScaffold(
    BuildContext context,
    AsyncValue<List<Promotion>> promotionsAsync,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: promotionsAsync.when(
                data: (promotions) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    child: Column(
                      children: [
                        _buildAddPromoSection(),
                        if (promotions.isNotEmpty) _buildPromoList(promotions),
                        const PromoAnalytics(),
                        _buildNotificationsAutoButton(),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: MerchantColors.gold)),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur: $err',
                      style: GoogleFonts.outfit(
                          color: MerchantColors.textLightGrey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Text(
              'Promotions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPromoSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: _isCreating ? null : _showAddPromoSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    );
  }

  Widget _buildNotificationsAutoButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GestureDetector(
        onTap: () => widget.onNavigate?.call('notifications-auto'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const Icon(Icons.chevron_right,
                  color: MerchantColors.gold, size: 24),
            ],
          ),
        ),
      ),
    );
  }

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
}
