part of 'discovery_screen.dart';

extension _DiscoveryScreenUi on _DiscoveryScreenState {
  Widget _buildHeader(BuildContext context) {
    final typeFilter = ref.watch(discoveryMerchantTypeFilterProvider);
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Découvrir',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.textWhite,
                      ),
                    ),
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
              if (widget.isDualProfile) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _typeChip(
                      label: 'Particuliers',
                      value: 'b2c',
                      current: typeFilter,
                      onTap: () {
                        ref
                            .read(discoveryMerchantTypeFilterProvider.notifier)
                            .state = 'b2c';
                        ref.invalidate(discoveryMerchantsProvider);
                      },
                    ),
                    const SizedBox(width: 8),
                    _typeChip(
                      label: 'Professionnels',
                      value: 'b2b',
                      current: typeFilter,
                      onTap: () {
                        ref
                            .read(discoveryMerchantTypeFilterProvider.notifier)
                            .state = 'b2b';
                        ref.invalidate(discoveryMerchantsProvider);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required String value,
    required String current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? MerchantColors.bgHeader : MerchantColors.textGrey,
          ),
        ),
      ),
    );
  }

  List<Merchant> _filterMerchants(List<Merchant> merchants) {
    if (_searchQuery.trim().isEmpty) return merchants;
    final q = _searchQuery.trim().toLowerCase();
    return merchants.where((m) {
      final name = (m.displayName ?? m.name).toLowerCase();
      final categories = m.categories?.join(' ').toLowerCase() ?? '';
      return name.contains(q) || categories.contains(q);
    }).toList();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(discoveryMerchantsProvider);
    await ref.read(discoveryMerchantsProvider.future);
  }

  Widget _buildContent(
    BuildContext context,
    List<Merchant> merchants,
    Set<String> viewedIds,
  ) {
    final filtered = _filterMerchants(merchants);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: MerchantColors.gold,
      backgroundColor: MerchantColors.bgHeader,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDescription(context),
            _buildPromoBanner(context),
            _buildSearchSection(context),
            _buildBusinessGrid(context, filtered, viewedIds),
            _buildInviteButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Text(
        'Des commerces recommandés par ceux que tu fréquentes déjà.',
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 13,
          height: 1.5,
          color: MerchantColors.textLightGrey,
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2540), Color(0xFF0E2A44)],
          ),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MerchantColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: MerchantColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'NOUVEAUTÉS',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: MerchantColors.gold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Découvrez les commerces\nde votre quartier',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.textWhite,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommandés par votre réseau',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textGrey,
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

  Widget _buildSearchSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchQueryChanged,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: MerchantColors.textWhite,
        ),
        cursorColor: MerchantColors.gold,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchStore,
          hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textGrey,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: MerchantColors.gold,
            size: 20,
          ),
          filled: true,
          fillColor: MerchantColors.bgHeader,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildBusinessGrid(
    BuildContext context,
    List<Merchant> merchants,
    Set<String> viewedIds,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: merchants.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucun commerce pour le moment',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: MerchantColors.textLightGrey,
                  ),
                ),
              ),
            )
          : GridView.builder(
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
                  onTap: () => widget.onStoreSelect(m.id),
                  placeholderBuilder: () => _placeholderImage(null),
                );
              },
            ),
    );
  }

  Widget _buildInviteButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            SharePlus.instance.share(
              ShareParams(
                text:
                    '📍 Rejoins Yuztoo — l\'app qui connecte les commerçants locaux et leurs clients !\n\nhttps://yuztoo.app/invite',
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

class _BusinessGridCard extends StatelessWidget {
  const _BusinessGridCard({
    required this.merchant,
    required this.hasViewed,
    required this.onTap,
    required this.placeholderBuilder,
  });

  final Merchant merchant;
  final bool hasViewed;
  final VoidCallback onTap;
  final Widget Function() placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    final name = merchant.displayName ?? merchant.name;
    final imageUrl = merchant.bannerUrl ?? merchant.logoUrl;
    final category =
        (merchant.categories?.isNotEmpty == true) ? merchant.categories!.first : null;
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
            // "Viewed" star badge
            if (hasViewed)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
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
