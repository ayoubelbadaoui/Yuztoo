part of 'notifications_screen.dart';

extension _NotificationsScreenUi on _NotificationsScreenState {
  Widget _buildNotificationsScaffold(
    BuildContext context,
    AsyncValue<List<ClientNotification>> notificationsAsync,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _NotificationsScreenState._overlayStyle,
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context, notificationsAsync),
            Expanded(
              child: notificationsAsync.when(
                data: (notifications) => notifications.isEmpty
                    ? _buildEmpty(context)
                    : _buildList(context, notifications),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: MerchantColors.gold),
                ),
                error: (_, __) => _buildEmpty(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<List<ClientNotification>> async,
  ) {
    final hasUnread = (async.valueOrNull ?? []).any((n) => !n.isRead);
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
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: MerchantColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasUnread)
                TextButton(
                  onPressed: _markAllRead,
                  child: Text(
                    'Tout lire',
                    style: GoogleFonts.outfit(color: MerchantColors.gold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: MerchantColors.gold,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suivez des commerces pour recevoir\nleurs promotions ici.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textLightGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification list ─────────────────────────────────────────────────────

  Widget _buildList(
      BuildContext context, List<ClientNotification> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final item = notifications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NotificationCard(
            notification: item,
            onTap: () => _markOneRead(item),
          ),
        );
      },
    );
  }
}

// ── Notification card ──────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final ClientNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(notification.type);
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? MerchantColors.bgHeader
            : MerchantColors.bgHeader.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MerchantColors.gold.withValues(
            alpha: notification.isRead ? 0.18 : 0.4,
          ),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon bubble ─────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(colors.icon, color: colors.foreground, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: MerchantColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.outfit(
                        color: MerchantColors.textLightGrey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: GoogleFonts.outfit(
                        color: MerchantColors.textGrey,
                        fontSize: 11,
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

  _NotificationColors _colorsFor(ClientNotificationType type) {
    switch (type) {
      case ClientNotificationType.promotion:
        return const _NotificationColors(
          background: Color(0xFFFDF5E6),
          foreground: Color(0xFFB8860B),
          icon: Icons.card_giftcard_outlined,
        );
      case ClientNotificationType.loyalty:
        return const _NotificationColors(
          background: Color(0xFFFDF5E6),
          foreground: Color(0xFFB8860B),
          icon: Icons.star_outline_rounded,
        );
      case ClientNotificationType.auto:
        return const _NotificationColors(
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF388E3C),
          icon: Icons.notifications_active_outlined,
        );
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} jours';
  }
}

class _NotificationColors {
  const _NotificationColors({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}
