part of 'client_home_screen.dart';

extension _ClientHomeScreenUi on ClientHomeScreen {
  Widget _buildHeader(
    BuildContext context, {
    required bool showMerchantSwitch,
  }) {
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
                    .withValues(alpha: MerchantColors.goldBorderStronger),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mon carnet Yuztoo',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                ),
              ),
              if (showMerchantSwitch)
                GestureDetector(
                  onTap: () => onNavigate('switch-to-merchant'),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MerchantColors.gold
                            .withValues(alpha: MerchantColors.goldBorderStronger),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.storefront_outlined,
                        color: MerchantColors.gold,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => onNavigate('qr-scanner'),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
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

  Widget _buildTagline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFF5F5F5), Color(0xFFD4A017)],
              stops: [0.45, 1.0],
            ).createShader(bounds),
            child: Text(
              'Mon carnet',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tous les commerces que tu aimes au même endroit',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(
    BuildContext context,
    WidgetRef ref,
    List<Merchant> merchants,
    Map<String, int> heartLevels, {
    List<String> followedIds = const [],
    String? ownMerchantId,
    // The Yuztoo brand vignette is a merchant-only affordance (it lets a
    // merchant viewing their own client carnet preview the Yuztoo
    // storefront). Pure clients should never see it. The parent passes
    // [hasLinkedMerchantAccountProvider] here, which combines the
    // canonical roles flag with a real merchant-doc lookup.
    bool showYuztooBrandTile = false,
  }) {
    if (merchants.isEmpty) {
      return _buildEmptyCarnet(
        context,
        showYuztooBrandTile: showYuztooBrandTile,
      );
    }

    // Order comes from [clientHomeFeedProvider] (sort_index + heart fallback).
    final followedSet = followedIds.toSet();

    return _CarnetList(
      merchants: merchants,
      heartLevels: heartLevels,
      followedSet: followedSet,
      ownMerchantId: ownMerchantId,
      showYuztooBrandTile: showYuztooBrandTile,
      onMerchantTap: (id) {
        if (onStoreSelect != null) {
          onStoreSelect!(id);
        } else {
          onNavigate('store-profile');
        }
      },
      onOrderChanged: (sortIndexes) {
        final userId = ref.read(auth_providers.currentUserIdProvider);
        if (userId == null) return;
        ref
            .read(followedMerchantsRepositoryProvider)
            .updateSortOrder(userId, sortIndexes)
            .then((result) {
          if (result.isRight) {
            ref.invalidate(clientHomeFeedProvider);
          }
        });
      },
    );
  }

  /// Clear loading state: no fake card or dummy text, avoids flash on app open.
  Widget _buildBusinessCardLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MerchantColors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chargement...',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textLightGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCardError(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MerchantColors.bgHeader,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: MerchantColors.gold.withValues(alpha: 0.5),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger ton carnet',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: MerchantColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                ref.invalidate(clientHomeFeedProvider);
                ref.invalidate(followedMerchantIdsForCurrentUserProvider);
                ref.invalidate(followedMerchantHeartLevelsForCurrentUserProvider);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCarnet(
    BuildContext context, {
    bool showYuztooBrandTile = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.stores,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  color: MerchantColors.gold.withValues(alpha: 0.7),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Suivez des commerces pour voir ici leurs offres, promotions et actualités.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: MerchantColors.textLightGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scanne un QR code ou découvre des commerces.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: MerchantColors.textGrey,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CarnetCta(
                      icon: Icons.qr_code_scanner_rounded,
                      label: AppLocalizations.of(context)!.scan,
                      onTap: () => onNavigate('qr-scanner'),
                    ),
                    const SizedBox(width: 12),
                    _CarnetCta(
                      icon: Icons.explore_outlined,
                      label: 'Découvrir',
                      onTap: () => onNavigate('discovery'),
                      outlined: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (showYuztooBrandTile) const _RestonsProchesTile(),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: MerchantColors.bgHeader,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _QuickAction(
              icon: Icons.qr_code_rounded,
              label: l10n.scan,
              onTap: () => onNavigate('qr-scanner'),
            ),
            _QuickAction(
              icon: Icons.star_border_rounded,
              label: l10n.loyaltyLabel,
              onTap: () => onNavigate('loyalty'),
            ),
            _QuickAction(
              icon: Icons.local_offer_outlined,
              label: l10n.offers,
              onTap: () => onNavigate('discovery'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsContent(
    BuildContext context,
    List<Promotion> promotions,
    List<Merchant> merchants,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final merchantNames = {
      for (final m in merchants) m.id: (m.displayName ?? m.name),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activePromotions,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate('discovery'),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (promotions.isEmpty)
            Text(
              'Aucune promotion pour le moment',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
              ),
            )
          else
            Column(
              children: promotions
                  .map((promo) => _buildPromoRow(
                        context,
                        promo,
                        merchantNames[promo.merchantId] ?? promo.subtitle,
                        promo.merchantId,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPromotionsLoading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activePromotions,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate('discovery'),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 24,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MerchantColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsError(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activePromotions,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate('discovery'),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune promotion',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoRow(
    BuildContext context,
    Promotion promo,
    String storeName,
    String? merchantId,
  ) {
    final now = DateTime.now();
    final daysLeft = promo.dateTo.isAfter(now)
        ? promo.dateTo.difference(now).inDays
        : 0;
    final expiresText = daysLeft > 0 ? '$daysLeft jours' : 'Expiré';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (merchantId != null && onStoreSelect != null) {
              onStoreSelect!(merchantId);
            } else {
              onNavigate('store-profile');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: MerchantColors.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storeName.isNotEmpty ? storeName : promo.subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: MerchantColors.textLightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    expiresText,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarnetCta extends StatelessWidget {
  const _CarnetCta({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: outlined
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFD4A017)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: outlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(12),
          border: outlined
              ? Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.6))
              : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: MerchantColors.gold.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: outlined
                    ? MerchantColors.gold
                    : MerchantColors.bgHeader),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: outlined
                    ? MerchantColors.gold
                    : MerchantColors.bgHeader,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MerchantColors.gold, width: 2),
              color: MerchantColors.gold.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: MerchantColors.gold, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful carnet list with optional search bar (auto-shown when > 6 merchants)
/// and reorder support.
class _CarnetList extends StatefulWidget {
  const _CarnetList({
    required this.merchants,
    required this.heartLevels,
    required this.followedSet,
    required this.onMerchantTap,
    this.ownMerchantId,
    this.onOrderChanged,
    this.showYuztooBrandTile = false,
  });

  final List<Merchant> merchants;
  final Map<String, int> heartLevels;
  final Set<String> followedSet;
  final void Function(String merchantId) onMerchantTap;
  final String? ownMerchantId;
  final void Function(Map<String, int> sortIndexes)? onOrderChanged;
  /// Whether the Yuztoo brand vignette ("Restons Proches") should be
  /// rendered at the bottom of the carnet. Reserved for users who also
  /// hold a merchant account — pure clients never see it.
  final bool showYuztooBrandTile;

  @override
  State<_CarnetList> createState() => _CarnetListState();
}

class _CarnetListState extends State<_CarnetList> {
  String _query = '';
  late List<Merchant> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = List<Merchant>.from(widget.merchants);
  }

  @override
  void didUpdateWidget(_CarnetList old) {
    super.didUpdateWidget(old);
    if (!carnetMerchantIdsEqualOrder(old.merchants, widget.merchants)) {
      _ordered = List<Merchant>.from(widget.merchants);
    }
  }

  List<Merchant> get _filtered {
    if (_query.isEmpty) return _ordered;
    final q = _query.toLowerCase();
    return _ordered.where((m) {
      final name = (m.displayName ?? m.name).toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = widget.merchants.length > 6;
    final filtered = _filtered;

    // Carnet order: own-merchant tile (dual profile), then followed merchants,
    // then the Yuztoo « restons proches » brand vignette at the bottom. Hidden during search.
    Merchant? ownMerchant;
    if (widget.ownMerchantId != null) {
      for (final m in filtered) {
        if (m.id == widget.ownMerchantId) {
          ownMerchant = m;
          break;
        }
      }
    }
    final showRestonsProches = _query.isEmpty && widget.showYuztooBrandTile;
    final showOwnMerchant = ownMerchant != null && _query.isEmpty;
    final reorderableList = showOwnMerchant
        ? filtered.where((m) => m.id != widget.ownMerchantId).toList()
        : filtered;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSearch) ...[
            TextField(
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.outfit(
                  color: MerchantColors.textWhite, fontSize: 14),
              cursorColor: MerchantColors.gold,
              decoration: InputDecoration(
                hintText: 'Rechercher un commerce…',
                hintStyle: GoogleFonts.outfit(
                    color: MerchantColors.textGrey, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: MerchantColors.gold, size: 20),
                filled: true,
                fillColor: MerchantColors.inputFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: MerchantColors.gold.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: MerchantColors.gold.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: MerchantColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (showOwnMerchant) ...[
            // Own merchant — pinned at top of list, NOT reorderable.
            _buildMerchantTile(
              ownMerchant,
              isLast: false,
              isReorderable: false,
            ),
            if (reorderableList.isNotEmpty) const SizedBox(height: 16),
          ],
          if (reorderableList.isNotEmpty && _query.isEmpty) ...[
            Text(
              'Maintenir une vignette pour réorganiser',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (reorderableList.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Disable the default drag-handle overlay; use long-press instead.
              buildDefaultDragHandles: false,
              itemCount: reorderableList.length,
              onReorder: (oldIndex, newIndex) {
                if (_query.isNotEmpty) return; // disable reorder during search
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  // Rebuild from the reorderable subset to avoid offset
                  // arithmetic bugs: simple +1 assumes ownMerchant is always
                  // at _ordered[0] which is not guaranteed.
                  final workingList = _ordered
                      .where((m) => m.id != widget.ownMerchantId)
                      .toList();
                  final item = workingList.removeAt(oldIndex);
                  workingList.insert(newIndex, item);
                  if (showOwnMerchant && ownMerchant != null) {
                    _ordered = [ownMerchant, ...workingList];
                  } else {
                    _ordered = workingList;
                  }
                });
                // Persist new order — skip own merchant (not in followed_merchants).
                final reorderable = _ordered
                    .where((m) => m.id != widget.ownMerchantId)
                    .toList();
                final indexes = {
                  for (var i = 0; i < reorderable.length; i++)
                    reorderable[i].id: i
                };
                widget.onOrderChanged?.call(indexes);
              },
              itemBuilder: (context, index) {
                final merchant = reorderableList[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(merchant.id),
                  index: index,
                  enabled: _query.isEmpty && reorderableList.isNotEmpty,
                  child: _buildMerchantTile(
                    merchant,
                    isLast: index == reorderableList.length - 1,
                    isReorderable: true,
                  ),
                );
              },
            ),
          if (showRestonsProches) ...[
            if (showSearch ||
                showOwnMerchant ||
                reorderableList.isNotEmpty)
              const SizedBox(height: 16),
            const _RestonsProchesTile(),
          ],
        ],
      ),
    );
  }

  /// Single source of truth for a carnet tile, used both as the pinned
  /// own-merchant tile and inside the ReorderableListView. `isReorderable`
  /// only changes the bottom padding handling so the pinned variant
  /// doesn't duplicate the section spacing.
  Widget _buildMerchantTile(
    Merchant merchant, {
    required bool isLast,
    required bool isReorderable,
  }) {
    final displayName = merchant.displayName ?? merchant.name;
    final imageUrl = merchant.bannerUrl ?? merchant.logoUrl;
    final isFollowed = widget.followedSet.contains(merchant.id);
    final heartLevel =
        isFollowed ? (widget.heartLevels[merchant.id] ?? 1) : 0;

    return Padding(
      padding: EdgeInsets.only(bottom: (isReorderable && !isLast) ? 16 : 0),
      child: GestureDetector(
        onTap: () => widget.onMerchantTap(merchant.id),
        child: Container(
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: MerchantColors.gold.withValues(
                  alpha: MerchantColors.goldBorderAlpha),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.textWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (merchant.id == widget.ownMerchantId)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MerchantColors.gold
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: MerchantColors.gold
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'Mon commerce',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: MerchantColors.gold,
                          ),
                        ),
                      )
                    else if (isReorderable || isFollowed)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isReorderable)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: 20,
                                color: MerchantColors.textGrey
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          if (isFollowed)
                            ...List.generate(
                              heartLevel.clamp(0, 3),
                              (i) => Padding(
                                padding:
                                    EdgeInsets.only(left: i == 0 ? 0 : 3),
                                child: const Icon(Icons.favorite,
                                    color: MerchantColors.gold, size: 16),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : _buildPlaceholderImage(),
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                      if (isFollowed)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Colors.black.withValues(alpha: 0.45),
                              border: Border.all(
                                  color: MerchantColors.gold,
                                  width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.star_rounded,
                                color: MerchantColors.gold, size: 18),
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
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 150,
      color: MerchantColors.bgMain,
      child: Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 36,
          color: MerchantColors.gold.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ─── Yuztoo "Restons Proches" brand vignette ────────────────────────────────
//
// Pinned at the top of the client carnet (above followed merchants). It is
// purely a brand surface (no real merchant doc), so taps open an
// informational bottom sheet rather than a vitrine. The visual style
// mirrors the surrounding carnet tiles (dark navy, gold border, banner-
// height aspect ratio) but uses gradient + Yuztoo iconography to read as
// "Yuztoo, not a shop".

class _RestonsProchesTile extends StatelessWidget {
  const _RestonsProchesTile();

  void _showBrandSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MerchantColors.bgHeader,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
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
                    color:
                        MerchantColors.textGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: AppLogo(size: 56),
              ),
              const SizedBox(height: 14),
              Text(
                'Yuztoo, restons proches',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le lien direct avec vos commerces préférés. Vos clients '
                'vous appartiennent — sans publicité, ni revente de '
                'données.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.55,
                  color: MerchantColors.textLightGrey,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MerchantColors.gold,
                  side: const BorderSide(color: MerchantColors.gold),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Compris',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showBrandSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: MerchantColors.bgHeader,
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MerchantColors.bgHeader,
              MerchantColors.gold.withValues(alpha: 0.10),
            ],
          ),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: MerchantColors.gold.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Yuztoo, restons proches',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.textWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MerchantColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Yuztoo',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: MerchantColors.darkOverlay,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MerchantColors.bgMain,
                        MerchantColors.gold.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Présentez votre carte Yuztoo',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                MerchantColors.textLightGrey,
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
}

