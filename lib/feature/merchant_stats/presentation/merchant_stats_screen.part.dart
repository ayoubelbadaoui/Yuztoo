part of 'merchant_stats_screen.dart';

extension _MerchantStatsScreenUi on _MerchantStatsScreenState {
  Widget _buildStatsBody(
    BuildContext context, {
    required String merchantId,
    required AsyncValue<List<MerchantClientRow>> clientsAsync,
    required AsyncValue<Storefront?> storefrontAsync,
    required AsyncValue<List<PendingClientRow>> pendingAsync,
    required AsyncValue<List<SentNotification>> sentNotifAsync,
    required AsyncValue<List<Promotion>> promotionsAsync,
  }) {
    final clients = clientsAsync.valueOrNull ?? <MerchantClientRow>[];
    final storefront = storefrontAsync.valueOrNull;
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;

    final connectedThisMonth =
        storefront?.rappelsMonthlyConnectedClients ?? 0;
    final passagesThisMonth =
        storefront?.rappelsMonthlyValidatedPassages ?? 0;

    final isLoading = clientsAsync.isLoading ||
        storefrontAsync.isLoading ||
        pendingAsync.isLoading;

    // Segment distribution
    final segmentCounts = <ClientSegment, int>{
      ClientSegment.nouveau: 0,
      ClientSegment.vip: 0,
      ClientSegment.habitue: 0,
      ClientSegment.abonne: 0,
    };
    for (final c in clients) {
      segmentCounts[c.segment] = (segmentCounts[c.segment] ?? 0) + 1;
    }

    // Top 5 clients by heartLevel desc
    final topClients = [...clients]
      ..sort((a, b) => b.heartLevel.compareTo(a.heartLevel));
    final top5 = topClients.take(5).toList();

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
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ── KPI grid ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.25,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildKpiCard(
                              icon: Icons.people_outline_rounded,
                              value: '${clients.length}',
                              label: 'Abonnés',
                              isLoading: clientsAsync.isLoading,
                            ),
                            _buildKpiCard(
                              icon: Icons.person_add_alt_1_rounded,
                              value: '$connectedThisMonth',
                              label: 'Nouveaux ce mois',
                              isLoading: storefrontAsync.isLoading,
                            ),
                            _buildKpiCard(
                              icon: Icons.loyalty_rounded,
                              value: '$passagesThisMonth',
                              label: 'Passages ce mois',
                              isLoading: storefrontAsync.isLoading,
                            ),
                            _buildKpiCard(
                              icon: Icons.pending_rounded,
                              value: '$pendingCount',
                              label: 'En attente',
                              isLoading: pendingAsync.isLoading,
                              highlight: pendingCount > 0,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      if (!isLoading && clients.isEmpty)
                        _buildEmptyState()
                      else ...[
                        // ── Segment chart ─────────────────────────────────
                        if (clients.isNotEmpty || isLoading)
                          _buildSegmentChart(context, segmentCounts,
                              loading: isLoading),

                        const SizedBox(height: 24),

                        // ── Top abonnés ───────────────────────────────────
                        if (top5.isNotEmpty) _buildTopClients(top5),

                        const SizedBox(height: 16),
                      ],

                      // ── Notification performance ──────────────────────
                      _buildNotifPerformanceSection(sentNotifAsync),

                      const SizedBox(height: 16),

                      // ── Promo performance ─────────────────────────────
                      _buildPromoPerformanceSection(promotionsAsync),

                      const SizedBox(height: 16),
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

  // ── Header with back button ──────────────────────────────────────────────

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
                    'Statistiques',
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

  // ── KPI card with animated shimmer ──────────────────────────────────────

  Widget _buildKpiCard({
    required IconData icon,
    required String value,
    required String label,
    bool isLoading = false,
    bool highlight = false,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLoading
                ? MerchantColors.navyCard
                    .withValues(alpha: _shimmerAnim.value)
                : MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? MerchantColors.gold
                  : MerchantColors.gold
                      .withValues(alpha: MerchantColors.goldBorderAlpha),
              width: highlight ? 1.5 : 1,
            ),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: MerchantColors.gold.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: highlight ? MerchantColors.gold : MerchantColors.gold,
                size: 22,
              ),
              isLoading
                  ? Container(
                      height: 28,
                      width: 60,
                      decoration: BoxDecoration(
                        color: MerchantColors.bgMain
                            .withValues(alpha: _shimmerAnim.value),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: highlight
                            ? MerchantColors.gold
                            : Colors.white,
                      ),
                    ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: MerchantColors.textGrey,
                ),
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              color: MerchantColors.gold.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Pas encore de données',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Partagez votre QR code pour obtenir vos premiers abonnés et voir vos statistiques ici.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Segment chart ────────────────────────────────────────────────────────

  Widget _buildSegmentChart(
    BuildContext context,
    Map<ClientSegment, int> counts, {
    bool loading = false,
  }) {
    final segments = [
      ClientSegment.nouveau,
      ClientSegment.habitue,
      ClientSegment.vip,
      ClientSegment.abonne,
    ];
    final colors = [
      const Color(0xFF64B5F6),
      const Color(0xFF4CAF50),
      const Color(0xFFFFD700),
      MerchantColors.gold,
    ];
    final labels = ['Nouveau', 'Habitué', 'VIP', 'Abonné'];

    final maxVal = segments
        .map((s) => (counts[s] ?? 0).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par segment',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (loading)
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, __) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: MerchantColors.bgMain
                        .withValues(alpha: _shimmerAnim.value),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal <= 0 ? 5 : maxVal * 1.3,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i < 0 || i >= labels.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[i],
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: MerchantColors.textGrey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: MerchantColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color:
                            MerchantColors.gold.withValues(alpha: 0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(segments.length, (i) {
                      final count =
                          (counts[segments[i]] ?? 0).toDouble();
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: count,
                            color: colors[i],
                            width: 28,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Top clients ───────────────────────────────────────────────────────────

  Widget _buildTopClients(List<MerchantClientRow> clients) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Top abonnés',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Top ${clients.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...clients.asMap().entries.map(
              (entry) {
                final rank = entry.key + 1;
                final c = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Rank badge
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$rank',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: rank == 1
                                ? MerchantColors.gold
                                : MerchantColors.textGrey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MerchantColors.bgMain,
                          border: Border.all(
                            color: _segmentColor(c.segment),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            c.displayLabel.isNotEmpty
                                ? c.displayLabel[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MerchantColors.gold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.displayLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _segmentColor(c.segment)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          c.segment.label,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _segmentColor(c.segment),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _segmentColor(ClientSegment seg) {
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

  // ── Notification performance section ─────────────────────────────────────
  Widget _buildNotifPerformanceSection(
      AsyncValue<List<SentNotification>> sentNotifAsync) {
    final notifications = sentNotifAsync.valueOrNull ?? [];
    final isLoading = sentNotifAsync.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFORMANCE DES NOTIFICATIONS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MerchantColors.textGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: MerchantColors.gold, strokeWidth: 2),
              ),
            )
          else if (notifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MerchantColors.navyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      color: MerchantColors.textGrey, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Aucune notification envoyée ce mois.',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: MerchantColors.textGrey),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _notifKpiCard(
                    icon: Icons.send_rounded,
                    value: '${notifications.length}',
                    label: 'Envoyées',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _notifKpiCard(
                    icon: Icons.people_outline_rounded,
                    value: '${notifications.first.sentCount}',
                    label: 'Dernière portée',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _notifKpiCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: MerchantColors.gold, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: MerchantColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ── Promo performance section ──────────────────────────────────────────────
  Widget _buildPromoPerformanceSection(
      AsyncValue<List<Promotion>> promotionsAsync) {
    final promotions = promotionsAsync.valueOrNull ?? [];
    final active = promotions.where((p) => p.isOnline).toList();
    final isLoading = promotionsAsync.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFORMANCE DES PROMOTIONS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MerchantColors.textGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: MerchantColors.gold, strokeWidth: 2),
              ),
            )
          else if (active.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MerchantColors.navyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined,
                      color: MerchantColors.textGrey, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Aucune promotion active.',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: MerchantColors.textGrey),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: MerchantColors.navyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.2)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: active.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: MerchantColors.gold.withValues(alpha: 0.12),
                ),
                itemBuilder: (context, i) {
                  final promo = active[i];
                  final startStr = _formatDate(promo.dateFrom);
                  final endStr = _formatDate(promo.dateTo);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: MerchantColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_offer_rounded,
                              color: MerchantColors.gold, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promo.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$startStr → $endStr',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: MerchantColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: MerchantColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${promo.viewCount} vues',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: MerchantColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}
