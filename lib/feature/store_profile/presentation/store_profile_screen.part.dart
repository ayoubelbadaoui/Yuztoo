part of 'store_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets (stateless, used by both state and skeleton)
// ─────────────────────────────────────────────────────────────────────────────

class _StoreProfileErrorBack extends StatelessWidget {
  const _StoreProfileErrorBack({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_outlined,
              size: 48, color: StorefrontColors.primaryGold),
          const SizedBox(height: 16),
          Text(
            'Commerce introuvable',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: StorefrontColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: StorefrontColors.primaryGold, size: 18),
            label: Text(
              'Retour',
              style: GoogleFonts.outfit(
                color: StorefrontColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a merchant's status is not 'active' (offline / draft).
/// Clients who reach the page via QR code or deep link see this instead of
/// the full storefront so they are never misled by stale content.
class _StoreProfileOffline extends StatelessWidget {
  const _StoreProfileOffline({
    required this.merchantName,
    required this.onBack,
  });

  final String merchantName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Minimal back header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: StorefrontColors.creamLight,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: StorefrontColors.navyDark,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        size: 36,
                        color: StorefrontColors.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      merchantName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: StorefrontColors.navyDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ce commerce est actuellement hors ligne.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: StorefrontColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Revenez plus tard ou contactez-le directement.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: StorefrontColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: StorefrontColors.primaryGold,
                        size: 16,
                      ),
                      label: Text(
                        'Retour',
                        style: GoogleFonts.outfit(
                          color: StorefrontColors.primaryGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header label (e.g. "Téléphone", "Adresse")
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: StorefrontColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Promotions list shown in the Accueil tab.
class _PromotionsList extends StatelessWidget {
  const _PromotionsList({
    required this.promotions,
    required this.onPromoTap,
  });
  final List<Promotion> promotions;
  final void Function(Promotion) onPromoTap;

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StorefrontColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E0D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined,
                  color: StorefrontColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Aucune promotion pour le moment',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: StorefrontColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: promotions.map((promo) {
          final now = DateTime.now();
          final isExpired = !promo.dateTo.isAfter(now);
          final daysLeft = isExpired
              ? 0
              : promo.dateTo.difference(now).inDays + 1;

          final validText = isExpired
              ? 'Expirée'
              : daysLeft == 1
                  ? 'Expire demain'
                  : 'Valide $daysLeft jours';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                color: StorefrontColors.cardLight,
                border: Border.all(
                  color: isExpired
                      ? const Color(0xFFE8E0D0)
                      : StorefrontColors.primaryGold.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
                child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: isExpired
                      ? null
                      : () => onPromoTap(promo),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isExpired
                                ? const Color(0xFFEEEEEE)
                                : StorefrontColors.primaryGold
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: isExpired
                                ? StorefrontColors.textSecondary
                                : StorefrontColors.primaryGold,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promo.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isExpired
                                      ? StorefrontColors.textSecondary
                                      : StorefrontColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                promo.subtitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: StorefrontColors.textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? const Color(0xFFEEEEEE)
                                      : StorefrontColors.primaryGold
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  validText,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isExpired
                                        ? StorefrontColors.textSecondary
                                        : StorefrontColors.primaryGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (!isExpired)
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: StorefrontColors.primaryGold,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — record a loyalty passage
// ─────────────────────────────────────────────────────────────────────────────

class _RecordLoyaltyPassageSheet extends ConsumerStatefulWidget {
  const _RecordLoyaltyPassageSheet({
    required this.merchant,
    required this.clientUid,
    required this.needsPurchaseAmount,
    required this.parentContext,
    this.isAlreadyFollowing = false,
  });

  final Merchant merchant;
  final String clientUid;
  final bool needsPurchaseAmount;
  /// Context of the parent screen — used to show the welcome-gift modal after
  /// this sheet is dismissed (its own context becomes invalid after pop).
  final BuildContext parentContext;
  /// When false, successfully recording a passage silently auto-follows the
  /// merchant so the client's loyalty card appears in their Fidélité tab.
  final bool isAlreadyFollowing;

  @override
  ConsumerState<_RecordLoyaltyPassageSheet> createState() =>
      _RecordLoyaltyPassageSheetState();
}

class _RecordLoyaltyPassageSheetState
    extends ConsumerState<_RecordLoyaltyPassageSheet> {
  final TextEditingController _amountController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    double? purchaseAmount;
    if (widget.needsPurchaseAmount) {
      final raw = _amountController.text.replaceAll(',', '.').trim();
      purchaseAmount = double.tryParse(raw);
      if (purchaseAmount == null || purchaseAmount <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indiquez un montant valide (€)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _busy = true);
    final useCase = ref.read(recordLoyaltyPassageProvider);
    final result = await useCase.call(
      clientUid: widget.clientUid,
      merchant: widget.merchant,
      purchaseAmountEuros: purchaseAmount,
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
      (progress) {
        // Capture what we need BEFORE popping (context becomes invalid after pop).
        final parentCtx = widget.parentContext;
        final welcomeGift = widget.merchant.welcomeGiftDescription?.trim() ?? '';
        final merchantName = widget.merchant.displayName?.isNotEmpty == true
            ? widget.merchant.displayName!
            : widget.merchant.name;

        // Auto-follow the merchant when the client records a passage without
        // already following — ensures their loyalty card appears in Fidélité.
        if (!widget.isAlreadyFollowing) {
          final toggleFollow = ref.read(toggleMerchantFollowProvider);
          unawaited(toggleFollow.call(
            userId: widget.clientUid,
            merchantId: widget.merchant.id,
            currentlyFollowing: false,
          ));
        }

        Navigator.of(context).pop();
        if (progress.isFirstVisit && welcomeGift.isNotEmpty) {
          // Use the parent screen's context — sheet context is invalid after pop.
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!parentCtx.mounted) return;
            showModalBottomSheet<void>(
              context: parentCtx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _WelcomeGiftSheet(
                merchantName: merchantName,
                welcomeGift: welcomeGift,
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passage enregistré ✓'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: StorefrontColors.primaryGold,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: StorefrontColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Enregistrer un passage',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: StorefrontColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.needsPurchaseAmount
                  ? 'Indiquez le montant de votre achat pour mettre à jour votre fidélité.'
                  : 'Confirmez votre passage en boutique pour valider votre fidélité.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.5,
                color: StorefrontColors.textSecondary,
              ),
            ),
            if (widget.needsPurchaseAmount) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Montant (€)',
                  hintText: 'ex. 24,90',
                  prefixIcon: const Icon(Icons.euro_rounded,
                      color: StorefrontColors.primaryGold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: StorefrontColors.primaryGold,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: StorefrontColors.primaryGold,
                foregroundColor: StorefrontColors.navyDark,
                disabledBackgroundColor:
                    StorefrontColors.primaryGold.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: StorefrontColors.navyDark,
                      ),
                    )
                  : Text(
                      'Valider',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome-gift celebration sheet (first visit only)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeGiftSheet extends StatelessWidget {
  const _WelcomeGiftSheet({
    required this.merchantName,
    required this.welcomeGift,
  });

  final String merchantName;
  final String welcomeGift;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: StorefrontColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              '🎉',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              'Bienvenue chez $merchantName !',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: StorefrontColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'C\'est votre première visite. Le commerçant vous offre :',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: StorefrontColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF9A825), Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                welcomeGift,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Montrez cette page au commerçant pour en bénéficier.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: StorefrontColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StorefrontColors.primaryGold,
                  foregroundColor: StorefrontColors.navyDark,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Merci !',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Main UI extension
// ─────────────────────────────────────────────────────────────────────────────

extension _StoreProfileScreenUi on _StoreProfileScreenState {
  Widget _buildContent(
    BuildContext context,
    Merchant merchant,
    List<Promotion> promotions,
  ) {
    final name = merchant.displayName ?? merchant.name;
    final activity = merchant.categories?.isNotEmpty == true
        ? merchant.categories!.join(' · ')
        : (merchant.city.isNotEmpty ? merchant.city : 'Commerçant');
    final hours = merchant.hours != null && merchant.hours!.isNotEmpty
        ? BusinessHours.fromMap(merchant.hours)
        : null;

    final userId = ref.watch(currentUserIdProvider);
    final followedIdsAsync =
        ref.watch(followedMerchantIdsForCurrentUserProvider);
    final heartLevelsAsync =
        ref.watch(followedMerchantHeartLevelsForCurrentUserProvider);
    final followersCountAsync = ref.watch(
      followersCountByMerchantIdsProvider(<String>[merchant.id]),
    );
    final viewedIdsAsync = ref.watch(viewedMerchantIdsForCurrentUserProvider);

    final isFollowing =
        followedIdsAsync.valueOrNull?.contains(merchant.id) ?? false;
    final hasViewed =
        viewedIdsAsync.valueOrNull?.contains(merchant.id) ?? false;

    _markMerchantAsViewed(userId, merchant.id);
    _maybeAutoOpenPassageSheetOnScan(
      context: context,
      merchant: merchant,
      userId: userId,
      isFollowing: isFollowing,
    );

    final baseHeartLevel = isFollowing
        ? (heartLevelsAsync.valueOrNull?[merchant.id] ?? 1)
        : (hasViewed ? 1 : 0);
    final heartLevel =
        _optimisticHeartMerchantId == merchant.id &&
                _optimisticHeartLevel != null
            ? _optimisticHeartLevel!
            : baseHeartLevel;

    final fetchedFollowersCount =
        followersCountAsync.valueOrNull?[merchant.id] ?? 0;
    final followersCount = isFollowing
        ? (fetchedFollowersCount < 1 ? 1 : fetchedFollowersCount)
        : fetchedFollowersCount;

    final loyaltyProgressAsync =
        ref.watch(clientLoyaltyProgressForMerchantProvider(merchant.id));

    return Stack(
      children: [
        // ── Scrollable body ──────────────────────────────────────────────────
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner (full-bleed, absorbs the status-bar space)
                StoreProfileBannerSection(
                  bannerImageUrl: merchant.bannerUrl ?? merchant.logoUrl,
                  profileImageUrl: merchant.logoUrl ?? merchant.bannerUrl,
                  topPadding: MediaQuery.of(context).padding.top,
                ),
                const SizedBox(height: 56), // room for the overlapping logo

                // ── Profile info ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + hearts
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: StorefrontColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          _buildHearts(context, merchant, heartLevel, userId),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Category / city
                      Text(
                        activity,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: StorefrontColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Followers pill
                      _FollowersPill(count: followersCount),
                      const SizedBox(height: 16),

                      // Loyalty block
                      _buildClientLoyaltyBlock(
                        context,
                        merchant,
                        loyaltyProgressAsync,
                        userId,
                        isFollowing: isFollowing,
                      ),
                      const SizedBox(height: 16),

                      // Action buttons
                      if (merchant.welcomeGiftDescription != null &&
                          merchant.welcomeGiftDescription!.trim().isNotEmpty &&
                          !isFollowing)
                        _buildWelcomeGiftCard(
                            merchant.welcomeGiftDescription!.trim()),
                      const SizedBox(height: 12),
                      _buildActionRow(context, merchant),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Tabs ─────────────────────────────────────────────────────
                NavigationTabs(
                  activeTab: _activeTab,
                  onTabChanged: _onTabChanged,
                ),
                const SizedBox(height: 16),

                // ── Tab content ──────────────────────────────────────────────
                if (_activeTab == 'accueil') ...[
                  _AccueilTab(
                    merchant: merchant,
                    promotions: promotions,
                    onPromoTap: (promo) => _showPromoDetail(context, promo),
                  ),
                ] else if (_activeTab == 'horaires') ...[
                  _HoraireTab(hours: hours),
                ] else if (_activeTab == 'actualite') ...[
                  _ActualiteTab(
                    imageUrls: merchant.newsImageUrls ?? const [],
                    description: merchant.description,
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // ── Back button overlay (always visible on top of banner) ────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _BackButton(onTap: widget.onBack),
        ),
      ],
    );
  }

  // ── Hearts row ─────────────────────────────────────────────────────────────

  Widget _buildHearts(
    BuildContext context,
    Merchant merchant,
    int heartLevel,
    String? userId,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final target = index + 1;
        final isActive = heartLevel >= target;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 8 : 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isFollowToggling
                ? null
                : () {
                    final next = heartLevel == target ? target - 1 : target;
                    _setHeartLevel(
                      context,
                      userId: userId,
                      merchantId: merchant.id,
                      level: next,
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                Icons.favorite_rounded,
                color: isActive
                    ? StorefrontColors.primaryGold
                    : StorefrontColors.textSecondary.withValues(alpha: 0.3),
                size: 22,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Welcome gift card (shown only to non-followers) ──────────────────────

  Widget _buildWelcomeGiftCard(String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: StorefrontColors.primaryGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StorefrontColors.primaryGold.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cadeau de bienvenue',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: StorefrontColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: StorefrontColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Follow / Unfollow button ───────────────────────────────────────────────

  Widget _buildActionRow(BuildContext context, Merchant merchant) {
    final merchantId = merchant.id;
    final userId = ref.watch(currentUserIdProvider);
    final followedAsync = ref.watch(followedMerchantIdsForCurrentUserProvider);
    final isFollowing =
        followedAsync.valueOrNull?.contains(merchantId) ?? false;

    Widget buttonChild;
    if (_isFollowToggling) {
      buttonChild = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: StorefrontColors.primaryGold,
        ),
      );
    } else if (isFollowing) {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_rounded,
              size: 18, color: StorefrontColors.primaryGold),
          const SizedBox(width: 6),
          Text(
            'Ne plus suivre',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: StorefrontColors.primaryGold,
            ),
          ),
        ],
      );
    } else {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_rounded,
              size: 18, color: StorefrontColors.navyDark),
          const SizedBox(width: 6),
          Text(
            'Suivre ce commerce',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: StorefrontColors.navyDark,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _isFollowToggling
                  ? null
                  : () async {
                      if (userId == null) {
                        final merchantName =
                            merchant.displayName?.isNotEmpty == true
                                ? merchant.displayName!
                                : merchant.name;
                        _showAuthGateSheet(
                          context,
                          merchant,
                          message:
                              'Connectez-vous pour suivre $merchantName et rester informé de ses actualités et promotions.',
                        );
                        return;
                      }
                      _setFollowToggling(true);
                      final toggleFollow = ref.read(toggleMerchantFollowProvider);
                      final result = await toggleFollow.call(
                        userId: userId,
                        merchantId: merchantId,
                        currentlyFollowing: isFollowing,
                      );
                      if (!context.mounted) return;
                      _setFollowToggling(false);
                      if (result.isLeft) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Échec de la sauvegarde'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      ref.invalidate(followedMerchantIdsForCurrentUserProvider);
                      ref.invalidate(
                          followedMerchantHeartLevelsForCurrentUserProvider);
                      ref.invalidate(clientHomeFeedProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFollowing
                                  ? 'Commerce retiré de votre carnet'
                                  : 'Commerce ajouté à votre carnet ✓',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: StorefrontColors.primaryGold,
                          ),
                        );
                      }
                    },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isFollowing
                      ? Colors.transparent
                      : StorefrontColors.primaryGold,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: StorefrontColors.primaryGold,
                    width: isFollowing ? 1.5 : 0,
                  ),
                ),
                alignment: Alignment.center,
                child: buttonChild,
              ),
            ),
          ),
          if (isFollowing && userId != null) ...[
            const SizedBox(width: 10),
            _MuteBellButton(userId: userId, merchantId: merchantId),
          ],
        ],
      ),
    );
  }

  // ── Loyalty block ──────────────────────────────────────────────────────────

  Widget _buildClientLoyaltyBlock(
    BuildContext context,
    Merchant merchant,
    AsyncValue<ClientMerchantLoyaltyProgress> progressAsync,
    String? userId, {
    bool isFollowing = false,
  }) {
    final summary = merchant.loyaltyClientSummaryForDisplay;
    final program = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
            loyaltyEnabled: merchant.loyaltyEnabled);
    final canRecordPassage =
        merchant.loyaltyEnabled && program.programEnabled;

    if (!merchant.loyaltyEnabled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StorefrontColors.primaryGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StorefrontColors.primaryGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: StorefrontColors.primaryGold, size: 16),
              const SizedBox(width: 6),
              Text(
                'Programme de fidélité',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.primaryGold,
                ),
              ),
            ],
          ),
          if (summary != null && summary.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary.trim(),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: StorefrontColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (canRecordPassage)
            progressAsync.when(
              data: (p) {
                final entry = ClientLoyaltyEntry(
                    merchant: merchant, config: program);
                final rewardAvailable = entry.isRewardAvailable(p);
                if (rewardAvailable) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            StorefrontColors.primaryGold.withValues(alpha: 0.18),
                            StorefrontColors.primaryGold.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: StorefrontColors.primaryGold,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard_rounded,
                              color: StorefrontColors.primaryGold, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🎁 Bon disponible !',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: StorefrontColors.primaryGold,
                                  ),
                                ),
                                Text(
                                  entry.rewardLabel(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: StorefrontColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final line = _loyaltyProgressSubtitle(merchant, program, p);
                if (line == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    line,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: StorefrontColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: StorefrontColors.primaryGold,
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          if (canRecordPassage) ...[
            const SizedBox(height: 12),
            // Tier status badge
            progressAsync.maybeWhen(
              data: (p) {
                final tier = ClientLoyaltyTier.fromPassages(p.validatedPassages);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tierColorStorefront(tier).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _tierColorStorefront(tier).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Votre statut : ${tier.label}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _tierColorStorefront(tier),
                      ),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openRecordPassageSheet(
                    context, merchant, userId,
                    isFollowing: isFollowing),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StorefrontColors.primaryGold,
                  side: const BorderSide(color: StorefrontColors.primaryGold),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(
                  'Enregistrer un passage',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String? _loyaltyProgressSubtitle(
    Merchant merchant,
    LoyaltyProgramConfig program,
    ClientMerchantLoyaltyProgress p,
  ) {
    if (!merchant.loyaltyEnabled || !program.programEnabled) return null;

    if (program.passageValidation == LoyaltyPassageValidation.manual) {
      if (p.pendingPassages <= 0) {
        return 'Vos passages seront validés par le commerçant.';
      }
      if (p.pendingPassages == 1) {
        return '1 passage en attente de validation.';
      }
      return '${p.pendingPassages} passages en attente de validation.';
    }

    if (program.triggerType == LoyaltyTriggerType.visitCount) {
      final need = program.visitsRequired.clamp(1, 9999);
      final v = p.validatedPassages;
      if (v >= need) return 'Objectif atteint — $need passages validés ✓';
      return '$v / $need passages — encore ${need - v} avant la récompense.';
    }

    final needSpend = program.cumulativeSpendRequiredEuros;
    final spent = p.cumulativeSpendEuros;
    if (spent >= needSpend) return 'Objectif d\'achats atteint ✓';
    final remain = needSpend - spent;
    final spentStr = _fmtEuro(spent);
    final needStr = _fmtEuro(needSpend);
    final remStr = remain == remain.roundToDouble()
        ? remain.toInt().toString()
        : remain.toStringAsFixed(2);
    return '$spentStr € / $needStr € — encore $remStr €.';
  }

  String _fmtEuro(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);

  void _showAuthGateSheet(
    BuildContext context,
    Merchant merchant, {
    String? message,
  }) {
    final name = merchant.displayName ?? merchant.name;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StorefrontColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: StorefrontColors.primaryGold.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      StorefrontColors.primaryGold.withValues(alpha: 0.15),
                      StorefrontColors.primaryGold.withValues(alpha: 0.25),
                    ],
                  ),
                  border: Border.all(
                    color: StorefrontColors.primaryGold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.loyalty_rounded,
                  color: StorefrontColors.primaryGold,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Connexion requise',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message ??
                    'Pour enregistrer votre passage chez $name et accumuler des points fidélité, veuillez vous connecter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: StorefrontColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onRequestLogin?.call();
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          StorefrontColors.primaryGold,
                          Color(0xFFB8860B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: StorefrontColors.primaryGold
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Se connecter / Créer un compte',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Continuer sans se connecter',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: StorefrontColors.textSecondary,
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

  void _openRecordPassageSheet(
    BuildContext context,
    Merchant merchant,
    String? userId, {
    bool isFollowing = false,
  }) {
    if (userId == null || userId.isEmpty) {
      _showAuthGateSheet(context, merchant);
      return;
    }
    final program = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
            loyaltyEnabled: merchant.loyaltyEnabled);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StorefrontColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _RecordLoyaltyPassageSheet(
          merchant: merchant,
          clientUid: userId,
          needsPurchaseAmount: program.effectiveAskClientPurchaseAmount,
          parentContext: context,
          isAlreadyFollowing: isFollowing,
        ),
      ),
    );
  }

  void _markMerchantAsViewed(String? userId, String merchantId) {
    if (userId == null || userId.isEmpty || merchantId.isEmpty) return;
    final key = '$userId::$merchantId';
    if (_lastViewedKey == key) return;
    _lastViewedKey = key;
    unawaited(
      ref
          .read(viewedMerchantsLocalServiceProvider)
          .markViewed(userId, merchantId),
    );
    ref.invalidate(viewedMerchantIdsForCurrentUserProvider);
  }

  /// Consumes [pendingScanAutoPassageProvider] exactly once per screen
  /// instance and auto-opens the loyalty-passage sheet for logged-in clients
  /// at merchants where loyalty is enabled. Other cases (guest, loyalty
  /// disabled) silently clear the flag — the spec keeps the vitrine front
  /// and centre and lets the user tap "Suivre ce commerce" themselves.
  ///
  /// Idempotency:
  /// - `_scanAutoPassageHandled` blocks re-firing on rebuild within the same
  ///   screen instance (e.g. when isFollowing flips after auto-follow).
  /// - The provider reset to `false` blocks re-firing if the user later
  ///   navigates away and back to the same storefront from the carnet.
  /// - The transaction-level cooldown blocks duplicate writes if the user
  ///   somehow reaches the use case twice (the sheet "Confirmer" button is
  ///   itself debounced, so this is belt-and-suspenders).
  void _maybeAutoOpenPassageSheetOnScan({
    required BuildContext context,
    required Merchant merchant,
    required String? userId,
    required bool isFollowing,
  }) {
    if (_scanAutoPassageHandled) return;
    final pending = ref.read(pendingScanAutoPassageProvider);
    if (!pending) return;

    _scanAutoPassageHandled = true;

    // Defer the provider reset and any sheet display past the current build
    // phase — Riverpod state mutations and showModalBottomSheet must not run
    // synchronously inside a build callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingScanAutoPassageProvider.notifier).state = false;

      // Guests stay on the vitrine — the spec ("CTA: Suivre ce commerce")
      // routes their first conversion through the follow CTA, not through a
      // surprise auth-gate modal.
      if (userId == null || userId.isEmpty) return;

      // Merchant disabled loyalty entirely — no sheet to show. Honour the
      // scan as a plain vitrine open.
      if (!merchant.loyaltyEnabled) return;
      final program = merchant.loyaltyProgram;
      if (program != null && !program.programEnabled) return;

      _openRecordPassageSheet(
        context,
        merchant,
        userId,
        isFollowing: isFollowing,
      );
    });
  }

  // ── Promo detail modal ──────────────────────────────────────────────────────
  void _showPromoDetail(BuildContext context, Promotion promo) {
    // Record a view when the client actually opens a promotion detail.
    // Best-effort: uses the same FieldValue.increment(1) batch under the hood.
    ref.read(recordPromoViewsProvider).call(
      merchantId: promo.merchantId,
      promotionIds: [promo.id],
    );

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.only(top: 80),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0D8CC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Promo image (if available)
            if (promo.imageUrl != null && promo.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  promo.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              const SizedBox(height: 8),

            const SizedBox(height: 16),

            // Icon + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: StorefrontColors.primaryGold
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: StorefrontColors.primaryGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: StorefrontColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          promo.subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: StorefrontColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: StorefrontColors.creamLight),
            const SizedBox(height: 14),

            // Validity dates
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: StorefrontColors.primaryGold),
                  const SizedBox(width: 8),
                  Text(
                    'Du ${fmt(promo.dateFrom)} au ${fmt(promo.dateTo)}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: StorefrontColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // View count
            if (promo.viewCount > 0) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 14,
                        color: StorefrontColors.primaryGold
                            .withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      '${promo.viewCount} vue${promo.viewCount > 1 ? 's' : ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: StorefrontColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),
            // Close CTA
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, MediaQuery.of(context).padding.bottom + 20),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: StorefrontColors.navyDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Small standalone widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Gold back button with a frosted-glass circular background — sits on the banner.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab content widgets
// ─────────────────────────────────────────────────────────────────────────────



// ─── Mute bell button ─────────────────────────────────────────────────────

class _MuteBellButton extends ConsumerWidget {
  const _MuteBellButton({required this.userId, required this.merchantId});

  final String userId;
  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muteAsync = ref.watch(
        merchantMuteStateProvider((userId: userId, merchantId: merchantId)));
    final isMuted = muteAsync.valueOrNull ?? false;

    return InkWell(
      onTap: () async {
        final setMute = ref.read(setMuteStateProvider);
        await setMute(userId, merchantId, muted: !isMuted);
        ref.invalidate(
            merchantMuteStateProvider((userId: userId, merchantId: merchantId)));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isMuted
                  ? 'Notifications réactivées'
                  : 'Notifications désactivées pour ce commerce'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: isMuted
                  ? StorefrontColors.primaryGold
                  : StorefrontColors.navyDark,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: StorefrontColors.primaryGold, width: 1.5),
          color: isMuted
              ? StorefrontColors.primaryGold.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Icon(
          isMuted
              ? Icons.notifications_off_outlined
              : Icons.notifications_outlined,
          color: StorefrontColors.primaryGold,
          size: 20,
        ),
      ),
    );
  }
}

Color _tierColorStorefront(ClientLoyaltyTier tier) {
  switch (tier) {
    case ClientLoyaltyTier.nouveau:
      return StorefrontColors.textSecondary;
    case ClientLoyaltyTier.soutien:
      return const Color(0xFF4FC3F7);
    case ClientLoyaltyTier.habitue:
      return StorefrontColors.primaryGold;
    case ClientLoyaltyTier.vip:
      return const Color(0xFFE040FB);
  }
}

// ─── URL launch helpers ────────────────────────────────────────────────────

Future<void> _launchPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  if (!await launchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le téléphone')),
      );
    }
  }
}

Future<void> _launchMaps(BuildContext context, String address) async {
  final encoded = Uri.encodeComponent(address);
  // Try Google Maps first; fallback to Apple Maps on iOS.
  final geoUri = Uri.parse('geo:0,0?q=$encoded');
  final mapsUri =
      Uri.parse('https://maps.apple.com/?q=$encoded');
  if (!await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
    if (!await launchUrl(mapsUri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir Maps')),
        );
      }
    }
  }
}

Future<void> _launchWebsite(BuildContext context, String url) async {
  final uri = Uri.tryParse(
      url.startsWith('http') ? url : 'https://$url');
  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le site')),
      );
    }
  }
}

/// Accueil tab — contact info + description + promotions + partner recommendations.
class _AccueilTab extends ConsumerWidget {
  const _AccueilTab({
    required this.merchant,
    required this.promotions,
    required this.onPromoTap,
  });
  final Merchant merchant;
  final List<Promotion> promotions;
  final void Function(Promotion) onPromoTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref
        .watch(partners_providers.merchantPartnersProvider(merchant.id));
    final partners = partnersAsync.valueOrNull ?? [];
    final confirmedPartners =
        partners.where((p) => !p.isPending).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        if (merchant.description != null &&
            merchant.description!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEE8DE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                merchant.description!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.65,
                  color: StorefrontColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Info card (phone + address grouped together)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEE8DE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: merchant.phone,
                  isFirst: true,
                  onTap: () => _launchPhone(context, merchant.phone),
                ),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFEEE8DE)),
                _InfoTile(
                  icon: Icons.place_outlined,
                  label: 'Adresse',
                  value: merchant.address ?? merchant.city,
                  isFirst: false,
                  onTap: () => _launchMaps(
                      context, merchant.address ?? merchant.city),
                ),
                if (merchant.websiteUrl != null &&
                    merchant.websiteUrl!.isNotEmpty) ...[
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFEEE8DE)),
                  _InfoTile(
                    icon: Icons.language_outlined,
                    label: 'Site web',
                    value: merchant.websiteUrl!,
                    isFirst: false,
                    onTap: () =>
                        _launchWebsite(context, merchant.websiteUrl!),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Promotions
        if (promotions.isNotEmpty) ...[
          const _SectionLabel('Promotions en cours'),
          const SizedBox(height: 4),
          _PromotionsList(
            promotions: promotions,
            onPromoTap: onPromoTap,
          ),
        ],

        if (promotions.isEmpty) const SizedBox(height: 8),

        // Recommended partners — only shown when partners exist
        if (confirmedPartners.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel('Recommandés par ce commerce'),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: confirmedPartners.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = confirmedPartners[i];
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(selectedStoreMerchantIdProvider.notifier)
                        .state = p.partnerMerchantId;
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: StorefrontColors.primaryGold
                              .withValues(alpha: 0.08),
                          border: Border.all(
                            color: StorefrontColors.primaryGold
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: p.partnerLogoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  p.partnerLogoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.store_rounded,
                                    color: StorefrontColors.primaryGold,
                                    size: 24,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.store_rounded,
                                color: StorefrontColors.primaryGold,
                                size: 24,
                              ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          p.partnerName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: StorefrontColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isFirst,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(onTap != null ? 12 : 0),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 14 : 12, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: StorefrontColors.primaryGold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: StorefrontColors.primaryGold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: StorefrontColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: onTap != null
                          ? StorefrontColors.primaryGold
                          : StorefrontColors.textPrimary,
                      height: 1.4,
                      decoration:
                          onTap != null ? TextDecoration.underline : null,
                      decorationColor: StorefrontColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: StorefrontColors.primaryGold, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Horaires tab — business hours with today highlighted.
class _HoraireTab extends StatelessWidget {
  const _HoraireTab({this.hours});
  final BusinessHours? hours;

  @override
  Widget build(BuildContext context) {
    if (hours == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEE8DE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  color: StorefrontColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Horaires non renseignés',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: StorefrontColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final todayName = _todayDayName();
    final h = hours!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exceptional closure banner — shown above the regular hours.
          if (h.hasExceptionalClosure) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade300, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fermeture exceptionnelle',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ce commerce est temporairement fermé. Les horaires habituels ne s\'appliquent pas.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Opacity(
            opacity: h.hasExceptionalClosure ? 0.45 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEE8DE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: h.allDays.asMap().entries.map((entry) {
            final i = entry.key;
            final day = entry.value;
            final isToday =
                day.dayName.toLowerCase() == todayName.toLowerCase();
            return Column(
              children: [
                if (i > 0)
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF5F0E8),
                      indent: 16,
                      endIndent: 16),
                Container(
                  color: isToday
                      ? StorefrontColors.primaryGold.withValues(alpha: 0.06)
                      : Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    child: Row(
                      children: [
                        if (isToday)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: StorefrontColors.primaryGold,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(width: 14),
                        Text(
                          day.dayName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isToday
                                ? StorefrontColors.primaryGold
                                : StorefrontColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          day.displayText,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isToday
                                ? StorefrontColors.primaryGold
                                : StorefrontColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _todayDayName() {
    const days = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche',
    ];
    return days[DateTime.now().weekday - 1];
  }
}

/// Actualité tab — merchant's photos + merchant's description text.
/// Read-only: the client sees what the merchant has published.
class _ActualiteTab extends StatelessWidget {
  const _ActualiteTab({
    required this.imageUrls,
    this.description,
  });
  final List<String> imageUrls;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return NewsSection(
      // Photos only — description lives in the Accueil tab
      content: null,
      imageUrls: imageUrls,
      showMedia: true,
      showDescription: false,
      showUploadButton: false,
    );
  }
}

/// Compact follower count pill.
class _FollowersPill extends StatelessWidget {
  const _FollowersPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count <= 1
        ? '$count abonné'
        : '$count abonnés';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: StorefrontColors.primaryGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: StorefrontColors.primaryGold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 13, color: StorefrontColors.primaryGold),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: StorefrontColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }
}
