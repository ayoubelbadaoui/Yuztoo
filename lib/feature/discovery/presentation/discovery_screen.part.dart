part of 'discovery_screen.dart';

extension _DiscoveryScreenUi on _DiscoveryScreenState {
  Widget _buildHeader(BuildContext context) {
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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recommandations',
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MerchantColors.bgHeader, MerchantColors.gold],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: MerchantColors.textWhite.withValues(alpha: 0.3),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 14,
                child: Text(
                  'À venir…',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: MerchantColors.textWhite.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage(double? height) {
    return Container(
      height: height,
      width: height != null ? double.infinity : null,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MerchantColors.gold, MerchantColors.cream],
        ),
      ),
      child: Center(
        child: Text(
          'Image commerce',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: MerchantColors.textGrey,
          ),
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
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchStore,
          hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.black54,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.black54,
            size: 22,
          ),
          filled: true,
          fillColor: MerchantColors.textWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            borderSide: BorderSide.none,
          ),
          disabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: MerchantColors.gold,
            foregroundColor: MerchantColors.bgHeader,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: Text(
            'Invite un commerçant',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => placeholderBuilder(),
                  )
                : placeholderBuilder(),
            if (hasViewed)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.star,
                  size: 16,
                  color: MerchantColors.gold,
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textWhite,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
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
