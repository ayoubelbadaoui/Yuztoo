import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../client_notification/application/providers.dart';

part 'notifications_screen.part.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, required this.onBack});

  static String get path => '/notifications';

  final VoidCallback onBack;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const SystemUiOverlayStyle _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: MerchantColors.bgHeader,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: MerchantColors.bgMain,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  Future<void> _markAllRead() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    final useCase = ref.read(markAllNotificationsReadProvider);
    await useCase(authState.user.id);
  }

  Future<void> _markOneRead(ClientNotification notification) async {
    if (notification.isRead) return;
    final useCase = ref.read(markNotificationReadProvider);
    await useCase(notification.clientId, notification.id);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
    final notificationsAsync = ref.watch(clientNotificationsStreamProvider);
    return _buildNotificationsScaffold(context, notificationsAsync);
  }
}
