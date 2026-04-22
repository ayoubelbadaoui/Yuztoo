part of 'account_preferences_screen.dart';

extension _AccountPreferencesScreenUi on _AccountPreferencesScreenState {
  Widget _buildAccountPreferencesBody(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final storefrontAsync = ref.watch(storefrontProvider);
    final isMerchant =
        authState is Authenticated && authState.user.isMerchant;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const ProfileAvatarSection(),
                    _buildConnectionsSection(0),
                    const CitiesSection(),
                    const YuztooCardBox(),
                    _buildCompletionSection(
                        storefrontAsync.valueOrNull?.profileCompletionPercentage ??
                            0),
                    _buildInfoSection(),
                    if (!isMerchant) _buildCreateAccountButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onBack?.call(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MerchantColors.gold, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: MerchantColors.gold, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Profil',
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

  Widget _buildConnectionsSection(int partnerCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Vous êtes connecté à\n',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
            TextSpan(
              text: partnerCount == 0
                  ? 'Aucun partenaire pour l\'instant'
                  : '$partnerCount professionnel${partnerCount > 1 ? 's' : ''} partenaire${partnerCount > 1 ? 's' : ''} Yuztoo',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MerchantColors.gold,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionSection(int percentage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profil complété à',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: MerchantColors.gold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$percentage%',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MerchantColors.darkOverlay,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  'Indépendant, artisan, commerçant, artiste ou association - '
                  'Restez connecté à vos clients et membres. Yuztoo est ',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
                height: 1.6,
              ),
            ),
            TextSpan(
              text: 'gratuit pour Eux pour Vous',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MerchantColors.gold,
                height: 1.6,
              ),
            ),
            TextSpan(
              text: '.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
                height: 1.6,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onCreateProAccount,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MerchantColors.gold, Color(0xFFD4AF37)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: MerchantColors.gold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Créer un compte pro',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MerchantColors.bgHeader,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
