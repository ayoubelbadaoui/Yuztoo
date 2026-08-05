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
                        color:
                            StorefrontColors.primaryGold.withValues(alpha: 0.1),
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
          final daysLeft =
              isExpired ? 0 : promo.dateTo.difference(now).inDays + 1;

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
                  onTap: isExpired ? null : () => onPromoTap(promo),
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
    required this.parentContext,
    this.isAlreadyFollowing = false,
    this.skipWelcomeOnPassage = false,
    this.visitOnly = false,
  });

  final Merchant merchant;
  final String clientUid;

  /// Passage seul (fidélité désactivée) — alimente la gratification client.
  final bool visitOnly;

  /// Context of the parent screen — used to show the welcome-gift modal after
  /// this sheet is dismissed (its own context becomes invalid after pop).
  final BuildContext parentContext;

  /// When false, successfully recording a passage silently auto-follows the
  /// merchant so the client's loyalty card appears in their Fidélité tab.
  final bool isAlreadyFollowing;

  /// When true, welcome modal was already shown (e.g. after scan follow).
  final bool skipWelcomeOnPassage;

  @override
  ConsumerState<_RecordLoyaltyPassageSheet> createState() =>
      _RecordLoyaltyPassageSheetState();
}

class _RecordLoyaltyPassageSheetState
    extends ConsumerState<_RecordLoyaltyPassageSheet> {
  bool _busy = false;

  Future<void> _submitVisitOnly() async {
    if (_busy) return;
    setState(() => _busy = true);

    final result = await ref.read(recordClientVisitPassageProvider).call(
          clientUid: widget.clientUid,
          merchant: widget.merchant,
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
        final parentCtx = widget.parentContext;
        final welcomeGift =
            widget.merchant.welcomeGiftDescription?.trim() ?? '';
        final merchantName = widget.merchant.displayName?.isNotEmpty == true
            ? widget.merchant.displayName!
            : widget.merchant.name;

        if (!widget.isAlreadyFollowing) {
          final toggleFollow = ref.read(toggleMerchantFollowProvider);
          unawaited(toggleFollow.call(
            userId: widget.clientUid,
            merchantId: widget.merchant.id,
            currentlyFollowing: false,
          ));
          ref.invalidate(followedMerchantIdsForCurrentUserProvider);
          ref.invalidate(followedMerchantHeartLevelsForCurrentUserProvider);
          ref.invalidate(clientHomeFeedProvider);
        }
        ref.invalidate(
          clientLoyaltyProgressForMerchantProvider(widget.merchant.id),
        );
        ref.invalidate(clientLoyaltyFeedProvider);

        Navigator.of(context).pop();
        if (!widget.skipWelcomeOnPassage &&
            progress.isFirstVisit &&
            welcomeGift.isNotEmpty) {
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
          final grat = widget.merchant.effectiveGratificationConfig;
          final tierLabel = grat.labelForPassages(progress.validatedPassages);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Passage enregistré — statut : $tierLabel'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: StorefrontColors.primaryGold,
            ),
          );
        }
      },
    );
  }

  Future<void> _submitRequest() async {
    if (_busy) return;
    if (isAutomaticPassageAllowedForMerchant(widget.merchant)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Votre passage est validé automatiquement lors du scan NFC ou QR.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour faire une demande.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _busy = true);

    // Follow first (await) so the client shell's session listeners include this
    // merchant before the validation doc appears — real-time completion UX.
    if (!widget.isAlreadyFollowing) {
      final toggleFollow = ref.read(toggleMerchantFollowProvider);
      await toggleFollow.call(
        userId: widget.clientUid,
        merchantId: widget.merchant.id,
        currentlyFollowing: false,
      );
      ref.invalidate(followedMerchantIdsForCurrentUserProvider);
      ref.invalidate(followedMerchantHeartLevelsForCurrentUserProvider);
      ref.invalidate(clientHomeFeedProvider);
      try {
        await ref.read(followedMerchantIdsForCurrentUserProvider.future);
      } catch (_) {}
    }

    final result = await ref.read(requestActiveValidationProvider).call(
          client: authState.user,
          merchant: widget.merchant,
        );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) {
        setState(() => _busy = false);
        if (!mounted) return;
        final parentCtx = widget.parentContext;
        Navigator.of(context).pop();
        ref.invalidate(
          clientActiveValidationSessionProvider(widget.merchant.id),
        );
        Future.microtask(() {
          if (!parentCtx.mounted) return;
          ScaffoldMessenger.of(parentCtx).showSnackBar(
            SnackBar(
              content: Text(
                'Demande envoyée à ${widget.merchant.displayName?.trim().isNotEmpty == true ? widget.merchant.displayName! : widget.merchant.name}. '
                'Vous pouvez continuer à utiliser l\'app — la validation apparaît '
                'en direct dans Fidélité.',
                style: GoogleFonts.outfit(fontSize: 14, height: 1.35),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grat = widget.merchant.effectiveGratificationConfig;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                  color: StorefrontColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ...[
              Text(
                widget.visitOnly
                    ? 'Enregistrer votre passage'
                    : 'Demander un passage',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.visitOnly
                    ? 'Votre visite est comptée pour votre statut chez ce commerce '
                        '(${grat.nouveauLabel}, ${grat.habituelLabel}, ${grat.vipLabel}).'
                    : 'Le commerçant validera votre passage depuis son appli. '
                        'Après votre confirmation, vous pourrez continuer à '
                        'utiliser Yuztoo — suivez l\'état en direct dans l\'onglet '
                        'Fidélité.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.5,
                  color: StorefrontColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy
                    ? null
                    : (widget.visitOnly ? _submitVisitOnly : _submitRequest),
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
    this.subtitle,
  });

  final String merchantName;
  final String welcomeGift;
  final String? subtitle;

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
              subtitle ??
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
    List<Promotion> promotions, {
    bool showOfflinePreviewBanner = false,
  }) {
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

    final isFollowListReady = followedIdsAsync.hasValue;
    final isFollowing =
        followedIdsAsync.valueOrNull?.contains(merchant.id) ?? false;
    final hasViewed =
        viewedIdsAsync.valueOrNull?.contains(merchant.id) ?? false;

    _markMerchantAsViewed(userId, merchant.id);
    _handleVitrineScanArrival(
      context: context,
      merchant: merchant,
      userId: userId,
      isFollowing: isFollowing,
      isFollowListReady: isFollowListReady,
    );
    _handlePromotionDeepLink(
      context: context,
      merchantId: merchant.id,
      promotions: promotions,
    );

    final baseHeartLevel = isFollowing
        ? (heartLevelsAsync.valueOrNull?[merchant.id] ?? 1)
        : (hasViewed ? 1 : 0);
    final heartLevel = _optimisticHeartMerchantId == merchant.id &&
            _optimisticHeartLevel != null
        ? _optimisticHeartLevel!
        : baseHeartLevel;

    final fetchedFollowersCount =
        followersCountAsync.valueOrNull?[merchant.id] ?? 0;
    final followersCount = isFollowing
        ? (fetchedFollowersCount < 1 ? 1 : fetchedFollowersCount)
        : fetchedFollowersCount;

    return Stack(
      children: [
        // ── Scrollable body ──────────────────────────────────────────────────
        Positioned.fill(
          child: RefreshIndicator(
            color: StorefrontColors.primaryGold,
            backgroundColor: Colors.white,
            displacement: 80,
            // Real refresh: invalidate every provider this screen reads from
            // and await the storefront page-data future before completing —
            // so the spinner stays up until the new data has actually
            // landed (not just been requested). Without awaiting `.future`
            // the spinner snaps back instantly and users assume "nothing
            // happened" because the new merchant/promotions paint a few
            // hundred ms later.
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              ref.invalidate(storeProfilePageDataProvider);
              ref.invalidate(followedMerchantIdsForCurrentUserProvider);
              ref.invalidate(followedMerchantHeartLevelsForCurrentUserProvider);
              ref.invalidate(
                  followersCountByMerchantIdsProvider(<String>[merchant.id]));
              ref.invalidate(viewedMerchantIdsForCurrentUserProvider);
              ref.invalidate(
                  clientLoyaltyProgressForMerchantProvider(merchant.id));
              try {
                await ref.read(storeProfilePageDataProvider.future);
              } catch (_) {
                // Even if the refresh fails, we still hide the spinner.
                // Riverpod's error state will surface in the body.
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
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

                  if (showOfflinePreviewBanner) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: StorefrontColors.primaryGold
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: StorefrontColors.primaryGold
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: StorefrontColors.primaryGold,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Aperçu — votre commerce est hors ligne. '
                                'Les clients ne voient pas cette vitrine '
                                'tant qu\'il n\'est pas en ligne.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: StorefrontColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

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

                        const SizedBox(height: 0),

                        // Welcome-gift card.
                        //
                        // Previously this hid the card the moment the client
                        // followed the merchant, which buried the welcome bon
                        // between "follow" and "claim" — users complained they
                        // could not find the bon ("premier cadeau de bienvenu
                        // est difficile à trouver"). The card now stays visible
                        // until the bon is actually claimed (or never offered),
                        // and is suppressed on the merchant's own preview
                        // because welcoming yourself makes no sense.
                        if ((merchant.welcomeGiftDescription
                                    ?.trim()
                                    .isNotEmpty ??
                                false) &&
                            !(ref
                                    .watch(
                                        clientLoyaltyProgressForMerchantProvider(
                                            merchant.id))
                                    .valueOrNull
                                    ?.welcomeBonClaimed ??
                                false) &&
                            userId != merchant.id)
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

                  // Discreet unfollow link sits at the absolute bottom of
                  // the storefront, after every tab content block. Only
                  // visible to signed-in followers — see
                  // [_buildBottomUnfollowLink] for design rationale.
                  _buildBottomUnfollowLink(context, merchant),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),

        // ── Back button overlay (always visible on top of banner) ────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _BackButton(onTap: widget.onBack),
        ),

        // ── Safety menu overlay (block / report) ─────────────────────────────
        // Hidden on the merchant's OWN storefront (preview view) — there's
        // nothing meaningful to block or report on yourself. Hidden for
        // guests too: blocking a shop is a per-account preference and
        // signalements need a verified reporter for moderation triage.
        if (userId != null && userId.isNotEmpty && userId != merchant.id)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _StorefrontMoreMenuButton(
              onTap: () => _openSafetyMenu(
                context,
                merchant: merchant,
                userId: userId,
              ),
            ),
          ),
      ],
    );
  }

  /// Bottom-sheet entry point for the per-storefront safety actions
  /// (block / report). Renders the actions live: if the user has already
  /// blocked this merchant, the first action becomes "Débloquer".
  void _openSafetyMenu(
    BuildContext context, {
    required Merchant merchant,
    required String userId,
  }) {
    final isBlockedAsync = ref.read(blockedMerchantIdsProvider).valueOrNull;
    final isBlocked =
        isBlockedAsync != null && isBlockedAsync.contains(merchant.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StorefrontColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _SafetyMenuSheet(
        merchantName: merchant.displayName?.isNotEmpty == true
            ? merchant.displayName!
            : merchant.name,
        isBlocked: isBlocked,
        onToggleBlock: () async {
          Navigator.of(sheetCtx).pop();
          if (isBlocked) {
            await _confirmAndUnblock(merchant: merchant, userId: userId);
          } else {
            await _confirmAndBlock(merchant: merchant, userId: userId);
          }
        },
        onReport: () {
          Navigator.of(sheetCtx).pop();
          _openReportSheet(merchant: merchant, userId: userId);
        },
      ),
    );
  }

  Future<void> _confirmAndBlock({
    required Merchant merchant,
    required String userId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StorefrontColors.backgroundLight,
        title: Text(
          'Bloquer ce commerce ?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: StorefrontColors.textPrimary,
          ),
        ),
        content: Text(
          'Vous ne recevrez plus aucune notification de ${merchant.displayName ?? merchant.name}, '
          'et il ne sera plus suggéré dans vos recommandations. '
          'Vous pouvez débloquer à tout moment depuis cette fiche.',
          style: GoogleFonts.outfit(
            color: StorefrontColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(color: StorefrontColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Bloquer',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref.read(userSafetyRepositoryProvider).blockMerchant(
          userId: userId,
          merchantId: merchant.id,
        );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        // Dropping the merchant from carnet & recommendations is the
        // strongest signal the user can give — pop back to the
        // previous shell rather than leaving them on a screen they
        // explicitly chose to silence.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commerce bloqué — vous ne recevrez plus rien.'),
          ),
        );
        widget.onBack();
      },
    );
  }

  Future<void> _confirmAndUnblock({
    required Merchant merchant,
    required String userId,
  }) async {
    final result = await ref.read(userSafetyRepositoryProvider).unblockMerchant(
          userId: userId,
          merchantId: merchant.id,
        );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commerce débloqué.')),
      ),
    );
  }

  void _openReportSheet({
    required Merchant merchant,
    required String userId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StorefrontColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom),
        child: _ReportSheet(merchantId: merchant.id, reporterUid: userId),
      ),
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
  //
  // Top-of-vitrine action row. Two distinct visual states by design:
  //
  //   * Not following → big gold primary CTA "Suivre ce commerce". This is
  //     the single most important action on the storefront for visitors,
  //     so it stays full-width and prominent.
  //
  //   * Already following → NO unfollow button here. Only the mute bell.
  //     Unfollow has been demoted to a small text link rendered at the very
  //     bottom of the scroll content (see [_buildBottomUnfollowLink]) so
  //     it does not compete with the primary content nor scare the user
  //     into accidental taps. Direct response to the feedback "Le bouton
  //     ne plus suivre est trop gros et doit être tout en bas".

  Widget _buildActionRow(BuildContext context, Merchant merchant) {
    final merchantId = merchant.id;
    final userId = ref.watch(currentUserIdProvider);
    final followedAsync = ref.watch(followedMerchantIdsForCurrentUserProvider);
    final isFollowing =
        followedAsync.valueOrNull?.contains(merchantId) ?? false;

    if (isFollowing) {
      // Followed: hide the big "Ne plus suivre" button entirely. Surface
      // only the mute bell here — the unfollow lives at the bottom now.
      if (userId == null) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.centerRight,
        child: _MuteBellButton(userId: userId, merchantId: merchantId),
      );
    }

    // Not following → primary "Suivre ce commerce" CTA, full-width gold.
    final Widget buttonChild = _isFollowToggling
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: StorefrontColors.navyDark,
            ),
          )
        : Row(
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

    return SizedBox(
      key: _followCtaKey,
      width: double.infinity,
      child: InkWell(
        onTap: _isFollowToggling
            ? null
            : () => _handleFollowToggle(
                  context: context,
                  merchant: merchant,
                  currentlyFollowing: false,
                ),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: StorefrontColors.primaryGold,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: buttonChild,
        ),
      ),
    );
  }

  // ── Bottom unfollow link ───────────────────────────────────────────────────
  //
  // Discreet text-only link rendered at the very bottom of the storefront
  // scroll. Only visible when the user is currently following AND signed in.
  //
  // Intentionally low-key (small font, secondary colour, no background or
  // border) so it cannot be tapped by accident and does not pull attention
  // away from the merchant's actualités, promos, and loyalty content. Keeps
  // the same toggle + 5s undo flow as before via [_handleFollowToggle].

  Widget _buildBottomUnfollowLink(BuildContext context, Merchant merchant) {
    final userId = ref.watch(currentUserIdProvider);
    final followedAsync = ref.watch(followedMerchantIdsForCurrentUserProvider);
    final isFollowing =
        followedAsync.valueOrNull?.contains(merchant.id) ?? false;
    if (!isFollowing || userId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Center(
        child: TextButton(
          onPressed: _isFollowToggling
              ? null
              : () => _handleFollowToggle(
                    context: context,
                    merchant: merchant,
                    currentlyFollowing: true,
                  ),
          style: TextButton.styleFrom(
            foregroundColor: StorefrontColors.textSecondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: _isFollowToggling
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: StorefrontColors.textSecondary,
                  ),
                )
              : Text(
                  'Ne plus suivre',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: StorefrontColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // (loyalty block removed — fidelité shown in dedicated Fidelité tab only)

  void _clearVitrineScanIntent() {
    ref.read(pendingVitrineScanIntentProvider.notifier).state =
        VitrineScanIntent.none;
  }

  bool _merchantLoyaltyActive(Merchant merchant) {
    if (!merchant.loyaltyEnabled) return false;
    final program = merchant.loyaltyProgram;
    if (program != null && !program.programEnabled) return false;
    return true;
  }

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

  /// QR/NFC scan while logged out — follow-the-store framing, not passage-first.
  ///
  /// Opened by [_handleVitrineScanArrival] on [ScanVisitGuest]: proposes
  /// login-to-follow with a "Continuer sans compte" escape hatch so the
  /// storefront stays browsable.
  void _showScanGuestConnectSheet(
    BuildContext context,
    Merchant merchant,
  ) {
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
              const Icon(
                Icons.storefront_rounded,
                size: 48,
                color: StorefrontColors.primaryGold,
              ),
              const SizedBox(height: 16),
              Text(
                'Rejoignez $name',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Connectez-vous pour suivre ce magasin, recevoir ses actualités et utiliser la fidélité.',
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
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Se connecter pour suivre',
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
                onTap: () {
                  Navigator.of(ctx).pop();
                  _clearVitrineScanIntent();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Continuer sans compte',
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

  void _removeFollowCoachmark() {
    _followCoachmarkEntry?.remove();
    _followCoachmarkEntry = null;
  }

  /// Spotlights the real "Suivre ce commerce" CTA so a logged-in non-follower
  /// understands that following is what registers their passage. Tapping the
  /// highlighted button follows AND chains straight into the fidélité flow via
  /// [_handleFollowToggle] (→ record passage automatic / open active_validation
  /// manual) — so there's no need to tap the badge / scan a second time.
  ///
  /// Falls back to [_showScanFollowFirstSheet] when the CTA isn't laid out
  /// (e.g. scrolled off-screen) so the funnel never dead-ends.
  void _showFollowPassageCoachmark(
    BuildContext context,
    Merchant merchant,
    String userId,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.mounted) return;
      final anchorCtx = _followCtaKey.currentContext;
      final overlay = Overlay.maybeOf(context);
      final box = anchorCtx?.findRenderObject() as RenderBox?;
      if (anchorCtx == null ||
          overlay == null ||
          box == null ||
          !box.hasSize) {
        _showScanFollowFirstSheet(context, merchant, userId);
        return;
      }
      final target = box.localToGlobal(Offset.zero) & box.size;
      final screen = MediaQuery.of(context).size;
      if (target.bottom < 0 || target.top > screen.height) {
        _showScanFollowFirstSheet(context, merchant, userId);
        return;
      }

      final loyaltyActive = _merchantLoyaltyActive(merchant);
      final name = merchant.displayName?.isNotEmpty == true
          ? merchant.displayName!
          : merchant.name;

      _removeFollowCoachmark();
      final entry = OverlayEntry(
        builder: (_) => _FollowPassageCoachmark(
          targetRect: target,
          title: loyaltyActive
              ? 'Suivez pour valider votre passage'
              : 'Suivez $name',
          message: loyaltyActive
              ? 'Ajoutez $name à votre carnet : votre passage sera enregistré automatiquement juste après.'
              : 'Ajoutez $name à votre carnet pour suivre ses actualités et ses avantages.',
          ctaHint: 'Touchez « Suivre ce commerce »',
          onTargetTap: () {
            _removeFollowCoachmark();
            _handleFollowToggle(
              context: context,
              merchant: merchant,
              currentlyFollowing: false,
            );
          },
          onDismiss: _removeFollowCoachmark,
        ),
      );
      _followCoachmarkEntry = entry;
      overlay.insert(entry);
    });
  }

  /// Logged-in client scanned but does not follow yet — follow before passage.
  ///
  /// Opened by [_handleVitrineScanArrival] on [ScanVisitNotFollowing]:
  /// "Suivre ce commerce" follows and then surfaces the welcome gift via
  /// [_afterScanFollowSuccess]; "Plus tard" leaves the storefront browsable
  /// (the regular Suivre CTA goes through [_handleFollowToggle]).
  Future<void> _showScanFollowFirstSheet(
    BuildContext context,
    Merchant merchant,
    String userId,
  ) async {
    final name = merchant.displayName ?? merchant.name;
    final loyaltyActive = _merchantLoyaltyActive(merchant);
    await showModalBottomSheet<void>(
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
              const SizedBox(height: 20),
              const Icon(
                Icons.favorite_rounded,
                size: 44,
                color: StorefrontColors.primaryGold,
              ),
              const SizedBox(height: 16),
              Text(
                'Suivez $name',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loyaltyActive
                    ? 'Ajoutez ce commerce à votre carnet Yuztoo. Vous validerez ensuite votre passage et profiterez de son programme de fidélité.'
                    : 'Ajoutez ce commerce à votre carnet Yuztoo pour suivre ses actualités et recevoir ses avantages.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: StorefrontColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StorefrontColors.primaryGold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: StorefrontColors.primaryGold.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  children: [
                    _scanFollowHelpStep(
                      Icons.favorite_rounded,
                      '1. Suivez ce commerce',
                      'Il rejoint votre carnet Yuztoo.',
                    ),
                    if (loyaltyActive) ...[
                      const SizedBox(height: 14),
                      _scanFollowHelpStep(
                        Icons.contactless_rounded,
                        '2. Validez votre passage',
                        'On enregistre votre visite juste après.',
                      ),
                      const SizedBox(height: 14),
                      _scanFollowHelpStep(
                        Icons.card_giftcard_rounded,
                        '3. Gagnez des récompenses',
                        'Profitez de son programme de fidélité.',
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      _scanFollowHelpStep(
                        Icons.notifications_active_rounded,
                        '2. Restez au courant',
                        'Recevez ses promos et nouveautés.',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    final toggleFollow = ref.read(toggleMerchantFollowProvider);
                    final result = await toggleFollow.call(
                      userId: userId,
                      merchantId: merchant.id,
                      currentlyFollowing: false,
                    );
                    if (!ctx.mounted) return;
                    if (result.isLeft) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
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
                    Navigator.of(ctx).pop();
                    if (!context.mounted) return;
                    await _afterScanFollowSuccess(context, merchant, userId);
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: StorefrontColors.primaryGold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      loyaltyActive ? 'Suivre et continuer' : 'Suivre ce commerce',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: StorefrontColors.navyDark,
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
                    'Plus tard',
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

  /// A single row of the "how it works" helper shown in the follow sheet.
  Widget _scanFollowHelpStep(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: StorefrontColors.primaryGold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StorefrontColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: StorefrontColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// After a non-follower follows from the scan sheet: surface the welcome
  /// gift (if configured), then **continue to the merchant's fidélité flow**
  /// — record the passage automatically (automatic mode → celebration) or
  /// open an `active_validations` session (manual mode → live banner).
  Future<void> _afterScanFollowSuccess(
    BuildContext context,
    Merchant merchant,
    String userId,
  ) async {
    final welcomeGift = merchant.welcomeGiftDescription?.trim() ?? '';
    final merchantName = merchant.displayName?.isNotEmpty == true
        ? merchant.displayName!
        : merchant.name;

    if (welcomeGift.isNotEmpty && _welcomeShownForMerchantId != merchant.id) {
      _welcomeShownForMerchantId = merchant.id;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _WelcomeGiftSheet(
          merchantName: merchantName,
          welcomeGift: welcomeGift,
          subtitle: 'Merci de nous suivre ! Le commerçant vous offre :',
        ),
      );
      if (!mounted || !context.mounted) return;
    }

    await _continueToFidelityFlowAfterFollow(context, merchant, userId);
  }

  /// Re-runs the vitrine scan logic now that the client follows, so the
  /// flow lands on the merchant's specific fidélité action. No-op when the
  /// merchant has no active loyalty programme.
  Future<void> _continueToFidelityFlowAfterFollow(
    BuildContext context,
    Merchant merchant,
    String userId,
  ) async {
    if (!_merchantLoyaltyActive(merchant)) return;

    final auth = ref.read(authStateProvider);
    final client = auth is Authenticated ? auth.user : null;
    if (client == null) return;

    final useCase = ref.read(processVitrineScanVisitProvider);
    final result = await useCase(
      client: client,
      merchant: merchant,
      isFollowing: true,
      isFollowListReady: true,
    );
    if (!mounted || !context.mounted) return;

    _applyScanVisitResult(
      context: context,
      merchant: merchant,
      userId: userId,
      result: result,
    );
  }

  /// **Legacy.** No longer auto-opened by [_handleVitrineScanArrival] in
  /// the NFC MVP — automatic-mode merchants get a silent visit + gold
  /// celebration overlay, manual-mode merchants get an
  /// `active_validations` session. Kept compiled so the manual "tap to
  /// validate" sheet stays one call away if a future flow re-needs it.
  // ignore: unused_element
  void _openRecordPassageSheet(
    BuildContext context,
    Merchant merchant,
    String? userId, {
    bool isFollowing = false,
    bool skipWelcomeOnPassage = false,
    bool visitOnly = false,
  }) {
    if (userId == null || userId.isEmpty) {
      _showAuthGateSheet(context, merchant);
      return;
    }
    final loyaltyActive = _merchantLoyaltyActive(merchant);
    final effectiveVisitOnly = visitOnly || !loyaltyActive;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StorefrontColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _RecordLoyaltyPassageSheet(
          merchant: merchant,
          clientUid: userId,
          parentContext: context,
          isAlreadyFollowing: isFollowing,
          skipWelcomeOnPassage: skipWelcomeOnPassage,
          visitOnly: effectiveVisitOnly,
        ),
      ),
    );
  }

  void _markMerchantAsViewed(String? userId, String merchantId) {
    if (userId == null || userId.isEmpty || merchantId.isEmpty) return;
    final key = '$userId::$merchantId';
    if (_lastViewedKey == key) return;
    _lastViewedKey = key;
    // Defer: [ref.invalidate] must not run while this screen is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(viewedMerchantsLocalServiceProvider)
            .markViewed(userId, merchantId),
      );
      ref.invalidate(viewedMerchantIdsForCurrentUserProvider);
    });
  }

  /// Consumes [pendingVitrineScanIntentProvider] once per screen visit.
  ///
  /// MVP funnel (post-NFC re-architecture):
  ///   * Guest → connect sheet ("Se connecter pour suivre", dismissible).
  ///   * Non-follower → follow-first sheet ("Suivre et continuer" + helper)
  ///     → [_afterScanFollowSuccess] shows the welcome gift, then continues
  ///     to the merchant's fidélité flow (visit/validation).
  ///   * Follower + automatic loyalty → silent visit + celebration overlay.
  ///   * Follower + manual loyalty → `active_validations` session (live banner).
  ///   * Cooldown blocked → friendly info snackbar.
  ///
  /// All branching is delegated to [ProcessVitrineScanVisit] so the in-app
  /// QR scanner, the deep link path, and the OS NFC tap behave identically.
  void _handleVitrineScanArrival({
    required BuildContext context,
    required Merchant merchant,
    required String? userId,
    required bool isFollowing,
    required bool isFollowListReady,
  }) {
    if (_scanArrivalHandled) return;
    if (ref.read(pendingVitrineScanIntentProvider) !=
        VitrineScanIntent.fromQrOrNfc) {
      return;
    }

    final loggedIn = userId != null && userId.isNotEmpty;
    // Wait until follow state is loaded so existing followers skip the
    // "not following" branch on a stale snapshot.
    if (loggedIn && !isFollowListReady) return;

    _scanArrivalHandled = true;

    // Called from build — clear intent + run funnel after the frame so we
    // never mutate providers while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _clearVitrineScanIntent();

      final auth = ref.read(authStateProvider);
      final client = auth is Authenticated ? auth.user : null;

      ScanVisitResult result;
      final forced = kNfcDebugEnabled
          ? ref.read(nfcDebugForcedScanVisitResultProvider)
          : null;
      if (forced != null) {
        ref.read(nfcDebugForcedScanVisitResultProvider.notifier).state = null;
        result = forced;
      } else {
        final useCase = ref.read(processVitrineScanVisitProvider);
        result = await useCase(
          client: client,
          merchant: merchant,
          isFollowing: isFollowing,
          isFollowListReady: isFollowListReady,
        );
      }

      if (!mounted || !context.mounted) return;

      _applyScanVisitResult(
        context: context,
        merchant: merchant,
        userId: userId,
        result: result,
      );
    });
  }

  void _applyScanVisitResult({
    required BuildContext context,
    required Merchant merchant,
    required String? userId,
    required ScanVisitResult result,
  }) {
      switch (result) {
        case ScanVisitGuest():
          // "au premier scan ... on doit proposer de suivre la boutique":
          // guests get a dismissible connect sheet — they can still browse
          // the storefront via "Continuer sans compte".
          _showScanGuestConnectSheet(context, merchant);
        case ScanVisitNotFollowing():
          // Logged-in non-follower → spotlight the real "Suivre" CTA with a
          // coachmark ("Suivez pour valider votre passage"). Tapping it follows
          // AND continues to the fidélité flow in one shot (no second scan),
          // because [_handleFollowToggle] already chains _afterScanFollowSuccess
          // → record passage (automatic) / open active_validation (manual).
          // Falls back to the bottom sheet if the button isn't laid out yet.
          _showFollowPassageCoachmark(context, merchant, userId!);
        case ScanVisitFollowListNotReady():
        case ScanVisitLoyaltyInactive():
          // Profile only — nothing actionable to propose.
          break;
        case ScanVisitVisitRecorded():
          ref.invalidate(
              clientLoyaltyProgressForMerchantProvider(merchant.id));
          ref
              .read(pendingDirectVisitCelebrationProvider.notifier)
              .state = merchant.id;
          break;
        case ScanVisitAwaitingMerchant():
          // The session listener (clientActiveValidationSessionProvider)
          // surfaces the live banner — no extra UI needed here.
          break;
        case ScanVisitCooldownBlocked(:final userMessage):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                userMessage,
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              backgroundColor: StorefrontColors.primaryGold,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        case ScanVisitError(:final userMessage):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                userMessage,
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
  }

  /// Consumes [pendingStorePromotionIdProvider] once per screen visit.
  ///
  /// Fired when the user taps a notification that references a specific
  /// promotion. We need the page data (promotions list) to be loaded
  /// before we can open the detail sheet — otherwise the promo doesn't
  /// exist in memory yet. The handler is idempotent across rebuilds.
  ///
  /// Edge cases handled:
  ///   - The pending id targets a different merchant (race during fast
  ///     re-tap) → leave the provider in place; the next navigation
  ///     with the matching merchant will consume it.
  ///   - The promotion was deleted between send and tap → silently
  ///     clear the provider; the user is still on the storefront, no
  ///     scary error dialog.
  void _handlePromotionDeepLink({
    required BuildContext context,
    required String merchantId,
    required List<Promotion> promotions,
  }) {
    if (_promotionDeepLinkHandled) return;
    final pendingId = ref.read(pendingStorePromotionIdProvider);
    if (pendingId == null || pendingId.isEmpty) return;
    if (promotions.isEmpty) return; // wait for the page data to resolve

    Promotion? match;
    for (final p in promotions) {
      if (p.id == pendingId && p.merchantId == merchantId) {
        match = p;
        break;
      }
    }

    _promotionDeepLinkHandled = true;
    // Always clear the one-shot — whether or not we found a match,
    // the next storefront visit must start fresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingStorePromotionIdProvider.notifier).state = null;
      final m = match;
      if (m != null) {
        _showPromoDetail(context, m);
      }
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
                      color:
                          StorefrontColors.primaryGold.withValues(alpha: 0.12),
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
        ref.invalidate(merchantMuteStateProvider(
            (userId: userId, merchantId: merchantId)));
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
  final mapsUri = Uri.parse('https://maps.apple.com/?q=$encoded');
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
  final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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
    final partnersAsync =
        ref.watch(partners_providers.merchantPartnersProvider(merchant.id));
    final partners = partnersAsync.valueOrNull ?? [];
    final confirmedPartners = partners.where((p) => !p.isPending).toList();
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
                  onTap: () =>
                      _launchMaps(context, merchant.address ?? merchant.city),
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
                    onTap: () => _launchWebsite(context, merchant.websiteUrl!),
                  ),
                ],
                for (final link in merchant.storefrontLinks) ...[
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFEEE8DE)),
                  _InfoTile(
                    icon: link.isLaunchableUrl
                        ? Icons.open_in_new_rounded
                        : Icons.info_outline_rounded,
                    label: link.label,
                    value: link.value,
                    isFirst: false,
                    onTap: link.isLaunchableUrl
                        ? () => _launchWebsite(context, link.value)
                        : null,
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
                    ref.read(selectedStoreMerchantIdProvider.notifier).state =
                        p.partnerMerchantId;
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
              child: Icon(icon, color: StorefrontColors.primaryGold, size: 18),
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
                            ? StorefrontColors.primaryGold
                                .withValues(alpha: 0.06)
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
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
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
    final label = count <= 1 ? '$count abonné' : '$count abonnés';
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

// ─────────────────────────────────────────────────────────────────────────────
// Storefront safety widgets — shared across the block + report flows.
// ─────────────────────────────────────────────────────────────────────────────

/// Round dark button mirroring the back-arrow button on the opposite
/// banner edge. The vertical 3-dot icon signals "more actions" without
/// committing visual real-estate to either action label.
class _StorefrontMoreMenuButton extends StatelessWidget {
  const _StorefrontMoreMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// Bottom sheet listing the safety actions for a storefront. The labels
/// adapt to whether the user has already blocked the merchant —
/// "Bloquer" / "Débloquer" — so the sheet is always actionable.
class _SafetyMenuSheet extends StatelessWidget {
  const _SafetyMenuSheet({
    required this.merchantName,
    required this.isBlocked,
    required this.onToggleBlock,
    required this.onReport,
  });

  final String merchantName;
  final bool isBlocked;
  final VoidCallback onToggleBlock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: StorefrontColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              merchantName,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: StorefrontColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _SafetyMenuRow(
              icon: isBlocked
                  ? Icons.notifications_active_outlined
                  : Icons.block_rounded,
              label:
                  isBlocked ? 'Débloquer ce commerce' : 'Bloquer ce commerce',
              destructive: !isBlocked,
              onTap: onToggleBlock,
            ),
            const SizedBox(height: 8),
            _SafetyMenuRow(
              icon: Icons.flag_outlined,
              label: 'Signaler',
              destructive: false,
              onTap: onReport,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: GoogleFonts.outfit(
                  color: StorefrontColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyMenuRow extends StatelessWidget {
  const _SafetyMenuRow({
    required this.icon,
    required this.label,
    required this.destructive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : StorefrontColors.textPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: StorefrontColors.textSecondary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: StorefrontColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full report flow rendered as an inline sheet rather than a separate
/// screen so the user never loses the storefront context. Reasons match
/// the Firestore-rules allowlist (snake_case wire form via
/// [ReportReason.wire]); the optional message is capped at 500 chars
/// client-side AND server-side.
class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.merchantId,
    required this.reporterUid,
  });

  final String merchantId;
  final String reporterUid;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason? _reason;
  final TextEditingController _msg = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final reason = _reason;
    if (reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un motif.')),
      );
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(userSafetyRepositoryProvider).submitReport(
          reporterUid: widget.reporterUid,
          targetType: ReportTargetType.merchant,
          targetId: widget.merchantId,
          reason: reason,
          message: _msg.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé. Notre équipe va l\'examiner.'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: StorefrontColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Signaler ce commerce',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: StorefrontColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Votre signalement est confidentiel. L\'équipe Yuztoo le '
              'traite sous 48h.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: StorefrontColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            for (final r in ReportReason.values)
              _ReportReasonTile(
                label: r.label,
                selected: _reason == r,
                onTap: () => setState(() => _reason = r),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _msg,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Détails (facultatif — 500 caractères max)',
                hintStyle: GoogleFonts.outfit(
                  color: StorefrontColors.textSecondary,
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: StorefrontColors.primaryGold,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: StorefrontColors.primaryGold,
                foregroundColor: StorefrontColors.navyDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: StorefrontColors.navyDark,
                      ),
                    )
                  : Text(
                      'Envoyer le signalement',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
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

class _ReportReasonTile extends StatelessWidget {
  const _ReportReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? StorefrontColors.primaryGold.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? StorefrontColors.primaryGold
                  : StorefrontColors.textSecondary.withValues(alpha: 0.25),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? StorefrontColors.primaryGold
                    : StorefrontColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: StorefrontColors.textPrimary,
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
