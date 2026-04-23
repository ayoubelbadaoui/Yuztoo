part of 'client_list_screen.dart';

extension _ClientListScreenUi on _ClientListScreenState {
  Widget _buildScaffold(
    BuildContext context,
    AsyncValue<List<MerchantClientRow>> clientsAsync,
    String merchantId,
  ) {
    final isApercu = _section == _Section.apercu;
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
          if (!didPop) widget.onBack();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabBar(),
                if (!isApercu) ...[
                  _buildSearchBar(),
                  _buildSegmentChips(),
                ],
                Expanded(
                  child: isApercu
                      ? _buildApercu(context, clientsAsync, merchantId)
                      : _buildBody(context, clientsAsync, merchantId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── tab bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      height: 44,
      color: MerchantColors.bgMain,
      child: Stack(
        children: [
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 1,
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderAlpha),
            ),
          ),
          Row(
            children: [
              _buildTab('Clients', _Section.list, Icons.people_outline_rounded),
              _buildTab('Aperçu', _Section.apercu, Icons.bar_chart_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, _Section section, IconData icon) {
    final active = _section == section;
    return Expanded(
      child: GestureDetector(
        onTap: () => setSection(section),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? MerchantColors.gold : MerchantColors.textGrey,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? MerchantColors.gold
                        : MerchantColors.textGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Active indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: active ? 48 : 0,
              decoration: BoxDecoration(
                color: MerchantColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────────

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
                onTap: widget.onBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MerchantColors.gold, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Vos clients',
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

  // ── search bar ───────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      color: MerchantColors.bgMain,
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
        cursorColor: MerchantColors.gold,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher un client…',
          hintStyle:
              GoogleFonts.outfit(fontSize: 14, color: MerchantColors.textGrey),
          prefixIcon:
              const Icon(Icons.search, color: MerchantColors.textGrey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: clearSearch,
                  child: const Icon(Icons.close,
                      color: MerchantColors.textGrey, size: 18),
                )
              : null,
          filled: true,
          fillColor: MerchantColors.navyCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: Color(0x1AFFFFFF), // subtle white border (style guide §8)
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: MerchantColors.gold.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ── segment chips ─────────────────────────────────────────────────────────────

  Widget _buildSegmentChips() {
    const segments = [
      null, // "Tous"
      ClientSegment.nouveau,
      ClientSegment.vip,
      ClientSegment.habitue,
      ClientSegment.abonne,
    ];

    final anyFilterActive = _segmentFilter != null || _searchQuery.isNotEmpty;

    return Container(
      height: 50,
      color: MerchantColors.bgMain,
      child: Stack(
        children: [
          // Bottom border
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 1,
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderAlpha),
            ),
          ),
          // Horizontally scrollable chips — centered vertically
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Segment chips
                ...segments.map((seg) {
                  final label = seg == null ? 'Tous' : seg.label;
                  final active = seg == null
                      ? (_segmentFilter == null && _searchQuery.isEmpty)
                      : _segmentFilter == seg;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setSegmentFilter(seg),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? MerchantColors.gold
                              : MerchantColors.navyCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? MerchantColors.gold
                                : MerchantColors.gold.withValues(
                                    alpha: MerchantColors.goldBorderStronger),
                          ),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? MerchantColors.darkOverlay
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // ── "Effacer" chip — only when a filter/search is active
                if (anyFilterActive)
                  GestureDetector(
                    onTap: () {
                      clearSearch();
                      setSegmentFilter(null);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded,
                              color: Colors.redAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Effacer',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── body ────────────────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<MerchantClientRow>> clientsAsync,
    String merchantId,
  ) {
    return clientsAsync.when(
      loading: _buildLoading,
      error: (err, __) => _buildError(),
      data: (clients) {
        if (clients.isEmpty) return _buildEmptyClients();
        final filtered = _applyFilters(clients);
        if (filtered.isEmpty) return _buildNoMatch();
        return _buildList(filtered, clients, merchantId);
      },
    );
  }

  Widget _buildLoading() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => _buildShimmerRow(_shimmerAnim.value),
      ),
    );
  }

  Widget _buildShimmerRow(double opacity) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.navyCard.withValues(alpha: opacity),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: MerchantColors.navyCard.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: MerchantColors.navyCard.withValues(alpha: opacity * 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 48,
            height: 18,
            decoration: BoxDecoration(
              color: MerchantColors.navyCard.withValues(alpha: opacity * 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade900.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: Colors.red.shade300, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger vos clients',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion et tirez\nvers le bas pour réessayer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyClients() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.gold.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.group_outlined,
                  color: MerchantColors.gold.withValues(alpha: 0.6), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun client pour l\'instant',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Partagez votre QR code pour que\nvos clients vous rejoignent.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatch() {
    final hasFilter = _segmentFilter != null;
    final hasSearch = _searchQuery.isNotEmpty;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          32,
          48,
          32,
          MediaQuery.of(context).viewInsets.bottom + 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.gold.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: MerchantColors.gold.withValues(alpha: 0.6),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun client trouvé',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch && hasFilter
                  ? 'Essayez d\'effacer la recherche ou le filtre de segment.'
                  : hasSearch
                      ? '« $_searchQuery » ne correspond à aucun client.'
                      : 'Aucun client dans ce segment pour le moment.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textGrey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                clearSearch();
                setSegmentFilter(null);
              },
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
                  'Effacer les filtres',
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

  Widget _buildList(
      List<MerchantClientRow> clients,
      List<MerchantClientRow> allClients,
      String merchantId) {
    final isFiltered = _segmentFilter != null || _searchQuery.isNotEmpty;
    return RefreshIndicator(
      color: MerchantColors.gold,
      backgroundColor: MerchantColors.navyCard,
      onRefresh: () async {
        ref.invalidate(crm_providers.merchantClientsProvider(merchantId));
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        itemCount: clients.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _buildListHeader(
              filtered: clients.length,
              total: allClients.length,
              isFiltered: isFiltered,
            );
          }
          final client = clients[i - 1];
          final isLast = i == clients.length;
          return _InsetDividerWrapper(
            showDivider: !isLast,
            child: ClientItemCard(
              name: client.displayLabel,
              subtitle: _subtitleFor(client),
              segment: client.segment,
              onTap: () => _showClientDetail(context, client, merchantId),
            ),
          );
        },
      ),
    );
  }


  // ── Aperçu tab ───────────────────────────────────────────────────────────────

  Widget _buildApercu(
    BuildContext context,
    AsyncValue<List<MerchantClientRow>> clientsAsync,
    String merchantId,
  ) {
    // Resolve the effective unfiltered client list (real or dummy)
    final allClients = clientsAsync.when(
      data: (list) => list,
      loading: () => const <MerchantClientRow>[],
      error: (_, __) => const <MerchantClientRow>[],
    );

    // Apply period filter only to "Nouveaux" count
    final cutoff = _apercuPeriod.cutoff;
    final nouveaux = cutoff == null
        ? allClients.length
        : allClients
            .where((c) =>
                c.followedAt != null && c.followedAt!.isAfter(cutoff))
            .length;

    final total = allClients.length;
    final vipCount =
        allClients.where((c) => c.segment == ClientSegment.vip).length;
    final engageCount = allClients
        .where((c) =>
            c.segment == ClientSegment.vip ||
            c.segment == ClientSegment.habitue)
        .length;
    final engagePct = total > 0 ? (engageCount * 100 ~/ total) : 0;

    // Promo views — real Firestore provider
    final promoViewsAsync =
        ref.watch(merchantTotalPromoViewsProvider(merchantId));
    final promoViews = promoViewsAsync.when(
      data: (v) => '$v',
      loading: () => '—',
      error: (_, __) => '0',
    );

    // Segment counts for bar chart
    final segCounts = <ClientSegment, int>{
      ClientSegment.vip: vipCount,
      ClientSegment.habitue:
          allClients.where((c) => c.segment == ClientSegment.habitue).length,
      ClientSegment.abonne:
          allClients.where((c) => c.segment == ClientSegment.abonne).length,
      ClientSegment.nouveau:
          allClients.where((c) => c.segment == ClientSegment.nouveau).length,
    };

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── period filter ─────────────────────────────────────────────────
          _buildApercuPeriodRow(),
          const SizedBox(height: 16),

          // ── stats grid ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.people_outline_rounded,
                  value: '$total',
                  label: 'Abonnés total',
                  color: MerchantColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.person_add_alt_1_rounded,
                  value: '$nouveaux',
                  label: _apercuPeriod == _ApercuPeriod.all
                      ? 'Nouveaux total'
                      : 'Nouveaux (${_apercuPeriod.label})',
                  color: const Color(0xFF4FC3F7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.workspace_premium_rounded,
                  value: '$vipCount',
                  label: 'Clients VIP',
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.visibility_outlined,
                  value: promoViews,
                  label: 'Vues promos',
                  color: const Color(0xFF64B5F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _statCardWide(
            icon: Icons.trending_up_rounded,
            value: '$engagePct%',
            label: 'Taux d\'engagement (VIP + Habitués / total)',
            color: const Color(0xFF4CAF50),
          ),

          const SizedBox(height: 20),

          // ── segment chart ─────────────────────────────────────────────────
          _buildSegmentChart(segCounts),
        ],
      ),
    );
  }

  Widget _buildApercuPeriodRow() {
    return Row(
      children: _ApercuPeriod.values.map((p) {
        final active = _apercuPeriod == p;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setApercuPeriod(p),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? MerchantColors.gold
                    : MerchantColors.navyCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? MerchantColors.gold
                      : MerchantColors.gold
                          .withValues(alpha: MerchantColors.goldBorderStronger),
                ),
              ),
              child: Text(
                p.label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? MerchantColors.darkOverlay
                      : Colors.white,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: MerchantColors.textGrey,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCardWide({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: MerchantColors.textGrey,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentChart(Map<ClientSegment, int> counts) {
    const segments = [
      ClientSegment.vip,
      ClientSegment.habitue,
      ClientSegment.abonne,
      ClientSegment.nouveau,
    ];
    const labels = ['VIP', 'Habitué', 'Abonné', 'Nouveau'];
    const colors = [
      Color(0xFFFFD700),
      Color(0xFF4CAF50),
      MerchantColors.gold,
      Color(0xFF4FC3F7),
    ];

    final maxVal = segments
        .map((s) => counts[s] ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.donut_small_rounded,
                color: MerchantColors.gold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Répartition par segment',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal <= 0 ? 5 : maxVal * 1.4,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => MerchantColors.bgHeader,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()}',
                      GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors[group.x],
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: colors[i],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          color: MerchantColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: MerchantColors.gold.withValues(alpha: 0.07),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(segments.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (counts[segments[i]] ?? 0).toDouble(),
                        color: colors[i],
                        width: 32,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal <= 0 ? 5 : maxVal * 1.4,
                          color: colors[i].withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader({
    required int filtered,
    required int total,
    required bool isFiltered,
  }) {
    final label = isFiltered
        ? '$filtered sur $total client${total > 1 ? 's' : ''}'
        : '$total client${total > 1 ? 's' : ''}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'filtré',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitleFor(MerchantClientRow c) {
    // Segment label is shown as the badge — only show city + date here
    final parts = <String>[];
    if (c.city?.isNotEmpty == true) parts.add(c.city!);
    if (c.followedAt != null) {
      final d = DateTime.now().difference(c.followedAt!).inDays;
      if (d == 0) {
        parts.add("Abonné aujourd'hui");
      } else if (d == 1) {
        parts.add('Abonné hier');
      } else {
        parts.add('Abonné il y a $d j');
      }
    }
    return parts.isEmpty ? c.segment.label : parts.join(' · ');
  }
}

// ── Inset divider wrapper ─────────────────────────────────────────────────────

class _InsetDividerWrapper extends StatelessWidget {
  const _InsetDividerWrapper({
    required this.child,
    this.showDivider = true,
  });

  final Widget child;
  final bool showDivider;

  // 20 (screen padding) + 48 (avatar) + 12 (gap) = 80
  static const double _inset = 80.0;

  @override
  Widget build(BuildContext context) {
    if (!showDivider) return child;
    return Stack(
      children: [
        child,
        Positioned(
          left: _inset,
          right: 0,
          bottom: 0,
          child: Container(
            height: 1,
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
      ],
    );
  }
}

// ── Client detail bottom sheet ────────────────────────────────────────────────

class _ClientDetailSheet extends ConsumerWidget {
  const _ClientDetailSheet({
    required this.client,
    required this.merchantId,
  });

  final MerchantClientRow client;
  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final seg = client.segment;
    final segColor = _segColor(seg);
    final initial = client.displayLabel.isNotEmpty
        ? client.displayLabel[0].toUpperCase()
        : '?';

    // Real loyalty progress from Firestore
    final progressAsync = ref.watch(
      merchantClientLoyaltyProgressProvider((
        merchantId: merchantId,
        clientUid: client.clientUid,
      )),
    );

    return Container(
      decoration: const BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar + name + segment
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: segColor.withValues(alpha: 0.15),
              border: Border.all(color: segColor, width: 2.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: segColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            client.displayLabel,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: segColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: segColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              seg.label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: segColor,
              ),
            ),
          ),

          if (client.city?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: MerchantColors.textGrey, size: 14),
                const SizedBox(width: 4),
                Text(
                  client.city!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: MerchantColors.textGrey,
                  ),
                ),
              ],
            ),
          ],

          if (client.followedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Client depuis ${_formatDate(client.followedAt!)}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 20),

          // Real stats from Firestore loyalty_clients
          progressAsync.when(
            loading: () => _buildStatsRow(
              validated: '—',
              pending: '—',
              days: _daysSince(client.followedAt),
            ),
            error: (_, __) => _buildStatsRow(
              validated: '0',
              pending: '0',
              days: _daysSince(client.followedAt),
            ),
            data: (progress) => _buildStatsRow(
              validated: '${progress.validatedPassages}',
              pending: '${progress.pendingPassages}',
              days: _daysSince(client.followedAt),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required String validated,
    required String pending,
    required String days,
  }) {
    return Row(
      children: [
        _statCell(validated, 'Passages'),
        _statCell(pending, 'En attente'),
        _statCell(days, 'Jours client'),
      ],
    );
  }

  Widget _statCell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: MerchantColors.gold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: MerchantColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _daysSince(DateTime? dt) {
    if (dt == null) return '—';
    return '${DateTime.now().difference(dt).inDays}';
  }

  Color _segColor(ClientSegment seg) {
    switch (seg) {
      case ClientSegment.vip:
        return const Color(0xFFFFD700);
      case ClientSegment.habitue:
        return const Color(0xFF4CAF50);
      case ClientSegment.nouveau:
        return const Color(0xFF64B5F6);
      case ClientSegment.abonne:
        return MerchantColors.gold;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
