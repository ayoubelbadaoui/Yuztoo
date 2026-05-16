part of 'notifications_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notifications Screen — UI
// ─────────────────────────────────────────────────────────────────────────────

extension _NotificationsScreenUi on _NotificationsScreenState {
  // ── Scaffold ────────────────────────────────────────────────────────────────

  Widget _buildScaffold(
    BuildContext context,
    AsyncValue<List<ClientNotification>> notificationsAsync,
    bool isGuest,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(notificationsAsync),
              // ── Tab pills ──────────────────────────────────────────────────
              _buildTabBar(),
              Expanded(
                child: _activeTab == 'alertes'
                    ? notificationsAsync.when(
                        data: (list) =>
                            list.isEmpty ? _buildEmpty(context) : _buildList(list),
                        loading: _buildShimmer,
                        error: (_, __) => _buildEmpty(context),
                      )
                    : isGuest
                        ? _buildGuestLocked(context)
                        : _buildPromosTab(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final notificationsAsync = ref.watch(clientNotificationsStreamProvider);
    final promosAsync = ref.watch(clientHomePromotionsProvider);
    final unreadNotifs =
        notificationsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;
    final promoCount = promosAsync.valueOrNull?.length ?? 0;

    return Container(
      color: MerchantColors.bgHeader,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _tabPill(
                  'alertes',
                  'Alertes',
                  Icons.notifications_rounded,
                  badge: unreadNotifs > 0 ? unreadNotifs : null,
                ),
                const SizedBox(width: 10),
                _tabPill(
                  'promos',
                  'Promotions',
                  Icons.local_offer_rounded,
                  badge: promoCount > 0 ? promoCount : null,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ],
      ),
    );
  }

  Widget _tabPill(String id, String label, IconData icon, {int? badge}) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => _setTab(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? MerchantColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? MerchantColors.gold
                : MerchantColors.gold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive
                  ? MerchantColors.bgHeader
                  : MerchantColors.textLightGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? MerchantColors.bgHeader
                    : MerchantColors.textLightGrey,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? MerchantColors.bgHeader
                      : MerchantColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? MerchantColors.gold
                        : MerchantColors.bgHeader,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Promos tab ──────────────────────────────────────────────────────────────

  Widget _buildPromosTab(BuildContext context) {
    final promosAsync = ref.watch(clientHomePromotionsProvider);
    return promosAsync.when(
      loading: _buildShimmer,
      error: (_, __) => _buildPromoEmpty(context),
      data: (promos) =>
          promos.isEmpty ? _buildPromoEmpty(context) : _buildPromoList(context, promos),
    );
  }

  Widget _buildPromoList(BuildContext context, List<Promotion> promos) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 88;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      itemCount: promos.length,
      itemBuilder: (context, index) {
        final promo = promos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PromoCard(
            promo: promo,
            onTap: () {
              // Record that the client opened this promotion.
              ref.read(recordPromoViewsProvider).call(
                    merchantId: promo.merchantId,
                    promotionIds: [promo.id],
                  );
              widget.onMerchantTap?.call(promo.merchantId);
            },
          ),
        );
      },
    );
  }

  Widget _buildPromoEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: MerchantColors.gold
                      .withValues(alpha: MerchantColors.goldBorderStronger),
                ),
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: MerchantColors.gold,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune promotion active',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MerchantColors.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les promotions des commerces que vous suivez apparaîtront ici.',
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

  // ── Guest locked ────────────────────────────────────────────────────────────

  Widget _buildGuestLocked(BuildContext context) {
    return Stack(
      children: [
        // Blurred placeholder cards suggesting real content
        IgnorePointer(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            itemCount: 4,
            itemBuilder: (_, i) {
              final opacity = 1.0 - (i * 0.18);
              return Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: MerchantColors.bgHeader,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: MerchantColors.gold.withValues(
                            alpha: MerchantColors.goldBorderAlpha),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: MerchantColors.gold.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: MerchantColors.gold.withValues(alpha: 0.4),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 11,
                                width: [130.0, 100.0, 150.0, 80.0][i],
                                decoration: BoxDecoration(
                                  color:
                                      MerchantColors.textGrey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 9,
                                width: [80.0, 60.0, 90.0, 50.0][i],
                                decoration: BoxDecoration(
                                  color:
                                      MerchantColors.textGrey.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Frosted overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MerchantColors.bgMain.withValues(alpha: 0.0),
                  MerchantColors.bgMain.withValues(alpha: 0.85),
                  MerchantColors.bgMain,
                ],
                stops: const [0.0, 0.4, 0.7],
              ),
            ),
          ),
        ),
        // Lock message
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold.withValues(alpha: 0.1),
                  border: Border.all(
                    color: MerchantColors.gold
                        .withValues(alpha: MerchantColors.goldBorderStronger),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: MerchantColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: MerchantColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'INVITÉ',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: MerchantColors.bgHeader,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connectez-vous pour voir\nles promotions en cours',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.textWhite,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accédez aux offres des commerces que vous suivez.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textLightGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => widget.onMerchantTap?.call(''),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: MerchantColors.gold.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Se connecter',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.bgHeader,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(AsyncValue<List<ClientNotification>> async) {
    final list = async.valueOrNull ?? [];
    final unreadCount = list.where((n) => !n.isRead).length;
    final hasAny = list.isNotEmpty;
    final isAlertes = _activeTab == 'alertes';

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
              // Left: trash icon — visible when on alertes tab and list non-empty
              SizedBox(
                width: 44,
                height: 44,
                child: (isAlertes && hasAny)
                    ? GestureDetector(
                        onTap: _deleteAll,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: MerchantColors.textGrey,
                            size: 20,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Alertes',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.textWhite,
                      ),
                    ),
                    if (unreadCount > 0 && isAlertes) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: MerchantColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: MerchantColors.bgHeader,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Right: "Tout lire" when there are unread alerts
              SizedBox(
                width: 44,
                height: 44,
                child: (unreadCount > 0 && isAlertes)
                    ? GestureDetector(
                        onTap: _markAllRead,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: MerchantColors.gold.withValues(
                                    alpha: MerchantColors.goldBorderStronger),
                              ),
                            ),
                            child: Text(
                              'Tout\nlire',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: MerchantColors.gold,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grouped notifications list ──────────────────────────────────────────────

  Widget _buildList(List<ClientNotification> notifications) {
    final groups = _groupByDate(notifications);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 88;

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final entry = groups[index];
        if (entry is _DateHeader) {
          return _buildDateLabel(entry.label);
        }
        final n = entry as ClientNotification;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _deleteOne(n),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 24),
            ),
            child: GestureDetector(
              onLongPress: () => _showActionSheet(context, n),
              child: _NotificationCard(
                notification: n,
                onTap: () => _handleTap(n),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: MerchantColors.textGrey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Future<void> _showActionSheet(
      BuildContext context, ClientNotification notification) async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    final userId = authState.user.id;
    final setMute = ref.read(setMuteStateProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: MerchantColors.textGrey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: Text(
                  'Supprimer cette alerte',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _deleteOne(notification);
                },
              ),
              if (notification.merchantId.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.notifications_off_outlined,
                      color: MerchantColors.textGrey),
                  title: Text(
                    'Mettre en sourdine ce commerce',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await setMute(userId, notification.merchantId, muted: true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications désactivées'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: MerchantColors.bgHeader,
                        ),
                      );
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  List<Object> _groupByDate(List<ClientNotification> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final result = <Object>[];
    String? lastLabel;

    for (final n in list) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final String label;
      if (!d.isBefore(today)) {
        label = "Aujourd'hui";
      } else if (!d.isBefore(yesterday)) {
        label = 'Hier';
      } else if (!d.isBefore(weekAgo)) {
        label = 'Cette semaine';
      } else {
        label = 'Plus ancien';
      }

      if (label != lastLabel) {
        result.add(_DateHeader(label));
        lastLabel = label;
      }
      result.add(n);
    }
    return result;
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: MerchantColors.gold
                      .withValues(alpha: MerchantColors.goldBorderStronger),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: MerchantColors.gold,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Pas encore d'alertes",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MerchantColors.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suivez des commerces pour recevoir leurs promotions et offres exclusives.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => widget.onMerchantTap?.call(''),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: MerchantColors.gold,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: MerchantColors.gold.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Découvrir des commerces',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
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

  // ── Shimmer loading ─────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: 5,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
        child: const _ShimmerCard(),
      ),
    );
  }
}

// ── Promo card (Promotions tab) ───────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.onTap});

  final Promotion promo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = promo.dateTo.difference(now).inDays + 1;
    final validText = daysLeft == 1 ? 'Expire demain' : 'Valide $daysLeft j';

    return Container(
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderStronger),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: MerchantColors.gold.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: MerchantColors.gold,
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
                          color: MerchantColors.textWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        promo.subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: MerchantColors.textLightGrey,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MerchantColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: MerchantColors.gold.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          validText,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: MerchantColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: MerchantColors.textGrey.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notification card ──────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final ClientNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(notification.type);
    final isUnread = !notification.isRead;

    return Container(
      decoration: BoxDecoration(
        // Unread: slightly brighter card; read: dimmed
        color: isUnread ? MerchantColors.bgHeader : const Color(0xFF0D2438),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread
              ? MerchantColors.gold.withValues(alpha: 0.4)
              : MerchantColors.gold.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: MerchantColors.gold.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: MerchantColors.gold.withValues(alpha: 0.06),
          highlightColor: MerchantColors.gold.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Type icon bubble ───────────────────────────────────────
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.fgColor, size: 22),
                ),
                const SizedBox(width: 12),

                // ── Text content ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: notification title + unread dot
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: MerchantColors.textWhite,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: MerchantColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Row 2: merchant name
                      const SizedBox(height: 2),
                      Text(
                        notification.merchantName,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: MerchantColors.gold
                              .withValues(alpha: 0.8),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Row 3: body text
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: MerchantColors.textLightGrey,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Row 4: timestamp + type chip
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _relativeTime(notification.createdAt),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: MerchantColors.textGrey,
                            ),
                          ),
                          if (notification.type ==
                              ClientNotificationType.promotion) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: MerchantColors.gold
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: MerchantColors.gold
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                'Promotion',
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
                    ],
                  ),
                ),

                // ── Chevron ────────────────────────────────────────────────
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: MerchantColors.textGrey.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _CardStyle _styleFor(ClientNotificationType type) {
    switch (type) {
      case ClientNotificationType.promotion:
        return _CardStyle(
          bgColor: MerchantColors.gold.withValues(alpha: 0.15),
          fgColor: MerchantColors.gold,
          icon: Icons.local_offer_rounded,
        );
      case ClientNotificationType.loyalty:
        return _CardStyle(
          bgColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          fgColor: const Color(0xFF60A5FA),
          icon: Icons.star_rounded,
        );
      case ClientNotificationType.auto:
        return _CardStyle(
          bgColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
          fgColor: const Color(0xFF4ADE80),
          icon: Icons.notifications_active_rounded,
        );
      case ClientNotificationType.bonExpiring:
        // Amber matches the in-app "expire bientôt" badge on the
        // reward card so the visual language is consistent across
        // surfaces (loyalty card → push → notifications list).
        return _CardStyle(
          bgColor: const Color(0xFFE8A93C).withValues(alpha: 0.15),
          fgColor: const Color(0xFFE8A93C),
          icon: Icons.warning_amber_rounded,
        );
      case ClientNotificationType.bonExpired:
        return _CardStyle(
          bgColor: Colors.redAccent.withValues(alpha: 0.12),
          fgColor: Colors.redAccent,
          icon: Icons.timer_off_rounded,
        );
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return 'Il y a ${(diff.inDays / 7).floor()} sem.';
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderAlpha),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circle avatar
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: MerchantColors.bgMain,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Text lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title line
                    Container(
                      height: 13,
                      width: 140,
                      decoration: BoxDecoration(
                        color: MerchantColors.bgMain,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Merchant line
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: MerchantColors.bgMain,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Body line
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: MerchantColors.bgMain,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DateHeader {
  const _DateHeader(this.label);
  final String label;
}

class _CardStyle {
  const _CardStyle({
    required this.bgColor,
    required this.fgColor,
    required this.icon,
  });
  final Color bgColor;
  final Color fgColor;
  final IconData icon;
}
