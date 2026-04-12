import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/shared/constants/merchant_colors.dart';

part 'notifications_screen.part.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.onBack});

  static String get path => '/notifications';

  final VoidCallback onBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Notification> notifications = <_Notification>[];
  static const SystemUiOverlayStyle _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: MerchantColors.bgHeader,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: MerchantColors.bgMain,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  List<_Notification> _buildNotifications(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _Notification(
        id: 1,
        title: l10n.newPromotion,
        message: 'Café Central: -20% sur toutes les boissons chaudes (aujourd\'hui).',
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
        message: l10n.messageFrom('Glovo Market'),
        time: l10n.yesterday,
        type: NotificationType.message,
        isRead: true,
      ),
      _Notification(
        id: 4,
        title: l10n.reservationReminder,
        message: 'Boulangerie Atlas: votre offre fidélité expire demain.',
        time: l10n.yesterday,
        type: NotificationType.reminder,
        isRead: true,
      ),
      _Notification(
        id: 5,
        title: l10n.newPromotion,
        message: 'Superette Lina: 2 achetés = 1 offert sur les jus.',
        time: l10n.hoursAgo(8),
        type: NotificationType.promotion,
        isRead: false,
      ),
      _Notification(
        id: 6,
        title: l10n.pointsEarned,
        message: l10n.pointsEarnedMessage(5, 'Coiffeur Nadir'),
        time: l10n.hoursAgo(12),
        type: NotificationType.points,
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

  void _markNotificationReadAt(int index) {
    setState(() {
      final item = notifications[index];
      notifications[index] = item.copyWith(isRead: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      notifications = _buildNotifications(context);
    }
    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
    return _buildNotificationsScaffold(context);
  }
}
