part of 'notifications_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notifications Screen — UI
// ─────────────────────────────────────────────────────────────────────────────

extension _NotificationsScreenUi on _NotificationsScreenState {
  // ── Scaffold ────────────────────────────────────────────────────────────────

  Widget _buildScaffold(
    BuildContext context,
    AsyncValue<List<ClientNotification>> notificationsAsync,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgHeader,
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
              Expanded(
                child: notificationsAsync.when(
                  data: (list) =>
                      list.isEmpty ? _buildEmpty(context) : _buildList(list),
                  loading: _buildShimmer,
                  error: (_, __) => _buildEmpty(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(AsyncValue<List<ClientNotification>> async) {
    final list = async.valueOrNull ?? [];
    final unreadCount = list.where((n) => !n.isRead).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
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
          // Title + unread badge
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Alertes',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.textWhite,
                  letterSpacing: -0.3,
                ),
              ),
              if (unreadCount > 0) ...[
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
          const Spacer(),
          // "Tout lire" — fixed width so header never shifts
          SizedBox(
            height: 32,
            child: unreadCount > 0
                ? TextButton(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: MerchantColors.gold.withValues(
                              alpha: MerchantColors.goldBorderStronger),
                        ),
                      ),
                    ),
                    child: Text(
                      'Tout lire',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.gold,
                      ),
                    ),
                  )
                : const SizedBox(width: 80),
          ),
        ],
      ),
    );
  }

  // ── Grouped list ───────────────────────────────────────────────────────────

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
          child: _NotificationCard(
            notification: n,
            onTap: () => _handleTap(n),
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
                decoration: BoxDecoration(
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
