part of 'account_preferences_screen.dart';

extension _AccountPreferencesScreenUi on _AccountPreferencesScreenState {
  Widget _buildAccountPreferencesBody(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final storefrontAsync = ref.watch(storefrontProvider);
    final user =
        authState is Authenticated ? authState.user : null;

    // [isMerchant] short-circuits on primary_role and so cannot tell us
    // whether a "primary client" already created a merchant account on
    // top — which is exactly the case where the "Créer un compte pro"
    // CTA must disappear. Use the canonical role flags instead.
    final hasMerchantRole = user?.hasMerchantRole ?? false;

    final merchantId = hasMerchantRole ? (user?.id ?? '') : '';
    final followerCountAsync =
        ref.watch(merchantFollowerCountProvider(merchantId));
    final partnerCount = hasMerchantRole
        ? (followerCountAsync.valueOrNull ?? 0)
        : 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.onBack?.call();
          },
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                  ),
                  child: Column(
                    children: [
                      ProfileAvatarSection(onEditProfile: widget.onEditProfile),
                      _buildConnectionsSection(partnerCount),
                      const CitiesSection(),
                      const YuztooCardBox(),
                      _buildCompletionSection(
                          storefrontAsync.valueOrNull?.profileCompletionPercentage ??
                              0),
                      _buildInfoSection(),
                      // Hide the "Créer un compte pro" CTA the moment
                      // the user already holds the merchant role.
                      // Previously gated by `!isMerchant`, which is
                      // primary-role-derived and so leaks the CTA to a
                      // primary-client user who already created their
                      // pro account (the user-reported regression).
                      if (!hasMerchantRole) _buildCreateAccountButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onBack?.call(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: MerchantColors.gold,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Mon profil',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded,
                  color: MerchantColors.gold, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partnerCount == 0
                        ? 'Aucun client pour l\'instant'
                        : '$partnerCount client${partnerCount > 1 ? 's' : ''} vous suivent',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Votre audience Yuztoo',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (partnerCount > 0)
              Text(
                '$partnerCount',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: MerchantColors.gold,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profil complété',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: MerchantColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.darkOverlay,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: MerchantColors.navyCard,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(MerchantColors.gold),
            ),
          ),
          if (percentage < 100) ...[
            const SizedBox(height: 8),
            Text(
              percentage < 50
                  ? 'Complétez votre storefront pour attirer plus de clients'
                  : 'Encore quelques détails pour un profil parfait',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
                height: 1.4,
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onCreateProAccount,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MerchantColors.gold, MerchantColors.goldLight],
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
            child: Text(
              'Créer un compte pro',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MerchantColors.bgHeader,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
