import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.onBack});

  static String get path => '/notifications';

  final VoidCallback onBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<_Notification> notifications;

  List<_Notification> _buildNotifications(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _Notification(
        id: 1,
        title: l10n.newPromotion,
        message: '20% de réduction chez Café Central',
        time: l10n.hoursAgo(2),
        type: NotificationType.promotion,
        isRead: false,
      ),
      _Notification(
        id: 2,
        title: l10n.pointsEarned,
        message: l10n.pointsEarnedMessage(10, 'Pharmacie El Amane'),
        time: l10n.hoursAgo(5),
        type: NotificationType.points,
        isRead: false,
      ),
      _Notification(
        id: 3,
        title: l10n.newMessage,
        message: l10n.messageFrom('Café Central'),
        time: l10n.yesterday,
        type: NotificationType.message,
        isRead: true,
      ),
      _Notification(
        id: 4,
        title: l10n.reservationReminder,
        message: l10n.reservationForTomorrow('19h'),
        time: l10n.yesterday,
        type: NotificationType.reminder,
        isRead: true,
      ),
    ];
  }
  
  @override
  void initState() {
    super.initState();
    // Will be set in build method
  }

  void _markAllRead() {
    setState(() {
      notifications =
          notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      notifications = _buildNotifications(context);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              IconButton(
                  onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: _markAllRead,
                child: Text(AppLocalizations.of(context)!.markAllRead),
              ),
            ],
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
                child: Card(
                  color: item.isRead ? Colors.white : YColors.accent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        notifications[index] = item.copyWith(isRead: true);
                      });
                    },
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
                            child: Icon(colors.icon, color: colors.foreground),
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
                                    Text(item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            color: YColors.secondary,
                                            shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item.message,
                                    style:
                                        const TextStyle(color: YColors.muted)),
                                const SizedBox(height: 6),
                                Text(item.time,
                                    style: const TextStyle(
                                        color: YColors.muted, fontSize: 12)),
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
            background: Color(0xFFE8F1FF),
            foreground: Color(0xFF1E64D0),
            icon: Icons.chat_bubble_outline);
      case NotificationType.reminder:
        return const _NotificationColors(
            background: Color(0xFFE9F5EE),
            foreground: Color(0xFF1E9E5B),
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
