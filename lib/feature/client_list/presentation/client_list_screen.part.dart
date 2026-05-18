part of 'client_list_screen.dart';

extension _ClientListScreenUi on _ClientListScreenState {
  Widget _buildValidateFab(BuildContext context) {
    final merchant =
        ref.read(merchant_providers.currentMerchantForOwnerProvider).valueOrNull;
    return FloatingActionButton.extended(
      onPressed: merchant == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MerchantBleScanScreen(merchant: merchant),
                  fullscreenDialog: true,
                ),
              ),
      backgroundColor: MerchantColors.gold,
      icon: const Icon(Icons.nfc_rounded, color: MerchantColors.bgMain),
      label: Text(
        'Valider un passage',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: MerchantColors.bgMain,
        ),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AsyncValue<List<MerchantClientRow>> clientsAsync,
    String merchantId,
  ) {
    final isList = _section == _Section.list;
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
          floatingActionButton: isList ? _buildValidateFab(context) : null,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabBar(),
                if (isList) ...[
                  _buildSearchBar(),
                  _buildSegmentChips(),
                ],
                Expanded(
                  child: switch (_section) {
                    _Section.apercu =>
                      _buildApercu(context, clientsAsync, merchantId),
                    _Section.validation => ClientValidationTab(
                        onNavigate: widget.onNavigate,
                      ),
                    _Section.list =>
                      _buildBody(context, clientsAsync, merchantId),
                  },
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
              _buildTab(
                'Validation',
                _Section.validation,
                Icons.how_to_reg_outlined,
              ),
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
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? MerchantColors.gold
                          : MerchantColors.textGrey,
                    ),
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
                    'Vos clients',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onSwitchRole,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MerchantColors.gold
                          .withValues(alpha: MerchantColors.goldBorderAlpha),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.switch_account,
                      color: MerchantColors.gold,
                      size: 20,
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
              const Icon(Icons.search_rounded, color: MerchantColors.textGrey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: clearSearch,
                  child: const Icon(Icons.close_rounded,
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
    // 'abonne' removed — the passage-based segment model never produces it.
    const segments = [
      null, // "Tous"
      ClientSegment.nouveau,
      ClientSegment.vip,
      ClientSegment.habitue,
      ClientSegment.inactif,
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
    final authState = ref.read(auth_providers.authStateProvider);
    final merchantId = authState is Authenticated ? authState.user.id : '';
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MerchantColors.gold.withValues(alpha: 0.08),
                  ),
                  child: Icon(Icons.group_outlined,
                      color: MerchantColors.gold.withValues(alpha: 0.6),
                      size: 28),
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
                  'Faites scanner votre QR pour connecter\nvotre premier client.',
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
          const SizedBox(height: 32),
          ClientQrBox(
            merchantId: merchantId,
            onTap: widget.onShowQr,
          ),
        ],
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
        itemCount: clients.length + 2, // QR + header
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              child: ClientQrBox(
                merchantId: merchantId,
                onTap: widget.onShowQr,
              ),
            );
          }
          if (i == 1) {
            return _buildListHeader(
              filtered: clients.length,
              total: allClients.length,
              isFiltered: isFiltered,
            );
          }
          final client = clients[i - 2];
          final isLast = i == clients.length + 1;
          return _InsetDividerWrapper(
            showDivider: !isLast,
            child: ClientItemCard(
              name: client.displayLabel,
              subtitle: _subtitleFor(client),
              photoUrl: client.photoUrl,
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

    // Segment counts for bar chart — 4 canonical segments, no 'abonne'.
    final segCounts = <ClientSegment, int>{
      ClientSegment.vip: vipCount,
      ClientSegment.habitue:
          allClients.where((c) => c.segment == ClientSegment.habitue).length,
      ClientSegment.nouveau:
          allClients.where((c) => c.segment == ClientSegment.nouveau).length,
      ClientSegment.inactif:
          allClients.where((c) => c.segment == ClientSegment.inactif).length,
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
                  label: 'Total des abonnés',
                  color: MerchantColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.person_add_alt_1_rounded,
                  value: '$nouveaux',
                  label: _apercuPeriod == _ApercuPeriod.all
                      ? 'Total des nouveaux'
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
                  label: 'Vues des promotions',
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
    // 4 canonical passage-based segments — 'abonne' removed.
    // Nouveau normalized to 0xFF64B5F6 (matches client_item_card + detail sheet).
    const segments = [
      ClientSegment.vip,
      ClientSegment.habitue,
      ClientSegment.nouveau,
      ClientSegment.inactif,
    ];
    const labels = ['VIP', 'Habitué', 'Nouveau', 'Inactif'];
    const colors = [
      Color(0xFFFFD700),
      Color(0xFF4CAF50),
      Color(0xFF64B5F6),
      Colors.grey,
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

class _ClientDetailSheet extends ConsumerStatefulWidget {
  const _ClientDetailSheet({
    required this.client,
    required this.merchantId,
  });

  final MerchantClientRow client;
  final String merchantId;

  @override
  ConsumerState<_ClientDetailSheet> createState() =>
      _ClientDetailSheetState();
}

class _ClientDetailSheetState extends ConsumerState<_ClientDetailSheet> {
  // Local "draft" of the tag the merchant has selected via chips but not yet
  // saved. `_initialised` distinguishes "no override at all" from "merchant
  // picked Auto" — both are stored as null but only the latter is a deliberate
  // user action that triggers the Save button to enable.
  ClientSegment? _draftSegment;
  bool _initialised = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Re-read the row from the live list so name/photo changes appear without
    // dismissing the sheet. Falls back to the snapshot passed in if the row
    // isn't in the list yet (race during initial open).
    final liveClient = ref
            .watch(
                crm_providers.merchantClientsProvider(widget.merchantId))
            .valueOrNull
            ?.firstWhere(
              (c) => c.clientUid == widget.client.clientUid,
              orElse: () => widget.client,
            ) ??
        widget.client;

    if (!_initialised) {
      _draftSegment = liveClient.manualSegment;
      _initialised = true;
    }
    // Effective segment for the badge: use the draft if the merchant has
    // changed it, otherwise the persisted manualSegment (which segment getter
    // already reflects). Auto-segment still applies when both are null.
    final effective = _draftSegment ?? liveClient.autoSegment;
    final segColor = _segColor(effective);
    final hasPhoto =
        liveClient.photoUrl != null && liveClient.photoUrl!.isNotEmpty;
    final dirty = _draftSegment != liveClient.manualSegment;

    // Real loyalty progress from Firestore
    final progressAsync = ref.watch(
      merchantClientLoyaltyProgressProvider((
        merchantId: widget.merchantId,
        clientUid: liveClient.clientUid,
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

          // Avatar — real photo if available, else generic person icon over
          // a coloured circle.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: segColor.withValues(alpha: 0.15),
              border: Border.all(color: segColor, width: 2.5),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? Image.network(
                      liveClient.photoUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: segColor,
                        size: 38,
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: segColor,
                      size: 38,
                    ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            liveClient.displayLabel,
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
              effective.label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: segColor,
              ),
            ),
          ),

          if (liveClient.city?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: MerchantColors.textGrey, size: 14),
                const SizedBox(width: 4),
                Text(
                  liveClient.city!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: MerchantColors.textGrey,
                  ),
                ),
              ],
            ),
          ],

          if (liveClient.followedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Client depuis ${_formatDate(liveClient.followedAt!)}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 16),

          // ── Manual tag selector ────────────────────────────────────────
          // The merchant picks a status here. Selection only updates LOCAL
          // state; the write happens when they tap the Save button below.
          // This avoids the previous UX where every chip tap triggered a
          // round-trip Firestore write that froze the sheet for ~1s.
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Statut',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textGrey,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ManualSegmentRow(
            selected: _draftSegment,
            autoSegment: liveClient.autoSegment,
            onSelect: (s) => setState(() => _draftSegment = s),
          ),
          const SizedBox(height: 14),
          // Save button — disabled when the draft matches the persisted value
          // so the merchant can't double-write the same tag.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (!dirty || _saving)
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      setState(() => _saving = true);
                      try {
                        await ref
                            .read(crm_providers
                                .setClientManualSegmentProvider)
                            .call(
                              merchantId: widget.merchantId,
                              clientUid: liveClient.clientUid,
                              segment: _draftSegment,
                            );
                        if (!mounted) return;
                        ref.invalidate(crm_providers
                            .merchantClientsProvider(widget.merchantId));
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 2),
                            backgroundColor: MerchantColors.navyCard,
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Le statut est mis à jour',
                              style: GoogleFonts.outfit(
                                color: MerchantColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          setState(() => _saving = false);
                          messenger.showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Impossible d\'enregistrer le statut',
                                style: GoogleFonts.outfit(),
                              ),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantColors.gold,
                foregroundColor: MerchantColors.bgHeader,
                disabledBackgroundColor:
                    MerchantColors.gold.withValues(alpha: 0.25),
                disabledForegroundColor:
                    MerchantColors.bgHeader.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: MerchantColors.bgHeader,
                      ),
                    )
                  : Text(
                      'Enregistrer',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 16),

          // Real stats from Firestore loyalty_clients
          progressAsync.when(
            loading: () => _buildStatsRow(
              validated: '—',
              spend: '—',
              days: _daysSince(liveClient.followedAt),
            ),
            error: (_, __) => _buildStatsRow(
              validated: '0',
              spend: '0',
              days: _daysSince(liveClient.followedAt),
            ),
            data: (progress) => _buildStatsRow(
              validated: '${progress.validatedPassages}',
              spend: '${progress.cumulativeSpendEuros.toStringAsFixed(0)} €',
              days: _daysSince(liveClient.followedAt),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required String validated,
    required String spend,
    required String days,
  }) {
    return Row(
      children: [
        _statCell(validated, 'Passages'),
        _statCell(spend, 'Cumul'),
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
      case ClientSegment.inactif:
        return Colors.grey;
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

/// Horizontal row of chips letting the merchant select a manual segment
/// label. This is **pure UI** — it only reports the selection back via
/// [onSelect]. The actual Firestore write happens when the parent's "Save"
/// button is tapped. The first chip ("Auto") clears any override.
class _ManualSegmentRow extends StatelessWidget {
  const _ManualSegmentRow({
    required this.selected,
    required this.autoSegment,
    required this.onSelect,
  });

  /// Currently-selected segment in the parent's draft state. Null means the
  /// "Auto" chip is active.
  final ClientSegment? selected;
  final ClientSegment autoSegment;
  final ValueChanged<ClientSegment?> onSelect;

  static const List<ClientSegment> _selectable = <ClientSegment>[
    ClientSegment.nouveau,
    ClientSegment.habitue,
    ClientSegment.vip,
    ClientSegment.inactif,
  ];

  Color _colorFor(ClientSegment s) {
    switch (s) {
      case ClientSegment.vip:
        return const Color(0xFFFFD700);
      case ClientSegment.habitue:
        return const Color(0xFF4CAF50);
      case ClientSegment.nouveau:
        return const Color(0xFF64B5F6);
      case ClientSegment.abonne:
        return MerchantColors.gold;
      case ClientSegment.inactif:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'Auto · ${autoSegment.label}',
            color: MerchantColors.gold,
            selected: selected == null,
            onTap: selected == null ? null : () => onSelect(null),
          ),
          const SizedBox(width: 8),
          for (final s in _selectable) ...[
            _Chip(
              label: s.label,
              color: _colorFor(s),
              selected: selected == s,
              onTap: selected == s ? null : () => onSelect(s),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : MerchantColors.textGrey,
          ),
        ),
      ),
    );
  }
}
