part of 'notifications_screen.dart';

extension _NotificationsScreenUi on _NotificationsScreenState {
  Widget _buildNotificationsScaffold(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _NotificationsScreenState._overlayStyle,
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            Container(
              color: MerchantColors.bgHeader,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: MerchantColors.bgHeader,
                    border: Border(
                      bottom: BorderSide(
                        color: MerchantColors.gold.withValues(
                            alpha: MerchantColors.goldBorderStronger),
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
                      TextButton(
                        onPressed: _markAllRead,
                        child: Text(
                          AppLocalizations.of(context)!.markAllRead,
                          style: const TextStyle(color: MerchantColors.gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  final colors = _colorsFor(item.type);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: item.isRead
                            ? MerchantColors.bgHeader
                            : MerchantColors.bgHeader.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: MerchantColors.gold.withValues(
                            alpha: item.isRead ? 0.18 : 0.35,
                          ),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _markNotificationReadAt(index),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colors.background,
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    Icon(colors.icon, color: colors.foreground),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: MerchantColors.textWhite,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (!item.isRead)
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
                                      item.message,
                                      style: const TextStyle(
                                        color: MerchantColors.textLightGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.time,
                                      style: const TextStyle(
                                        color: MerchantColors.textGrey,
                                        fontSize: 12,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotificationColors _colorsFor(NotificationType type) {
    switch (type) {
      case NotificationType.promotion:
        return const _NotificationColors(
            background: Color(0xFFFDF5E6),
            foreground: YColors.secondary,
            icon: Icons.card_giftcard);
      case NotificationType.points:
        return const _NotificationColors(
            background: Color(0xFFFDF5E6),
            foreground: YColors.secondary,
            icon: Icons.star_border);
      case NotificationType.message:
        return const _NotificationColors(
            background: Color(0xFFFDF5E6),
            foreground: YColors.secondary,
            icon: Icons.chat_bubble_outline);
      case NotificationType.reminder:
        return const _NotificationColors(
            background: Color(0xFFFDF5E6),
            foreground: YColors.secondary,
            icon: Icons.calendar_today_outlined);
    }
  }
}

enum NotificationType { promotion, points, message, reminder }

class _Notification {
  const _Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });

  final int id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isRead;

  _Notification copyWith({bool? isRead}) => _Notification(
        id: id,
        title: title,
        message: message,
        time: time,
        type: type,
        isRead: isRead ?? this.isRead,
      );
}

class _NotificationColors {
  const _NotificationColors(
      {required this.background, required this.foreground, required this.icon});
  final Color background;
  final Color foreground;
  final IconData icon;
}
