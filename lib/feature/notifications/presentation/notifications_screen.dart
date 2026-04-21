import 'dart:async' show unawaited;

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
  const NotificationsScreen({
    super.key,
    this.onMerchantTap,
    this.onPromotionTap,
  });

  /// Called when a notification without a specific promotion is tapped.
  final void Function(String merchantId)? onMerchantTap;

  /// Called when a promotion notification with a promotionId is tapped.
  final void Function(String merchantId, String promotionId)? onPromotionTap;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Future<void> _markAllRead() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    final useCase = ref.read(markAllNotificationsReadProvider);
    await useCase(authState.user.id);
  }

  Future<void> _handleTap(ClientNotification notification) async {
    // 1. Mark read fire-and-forget
    if (!notification.isRead) {
      final useCase = ref.read(markNotificationReadProvider);
      unawaited(useCase(notification.clientId, notification.id));
    }
    // 2. Deep-link navigation
    if (notification.promotionId != null &&
        widget.onPromotionTap != null) {
      widget.onPromotionTap!(notification.merchantId, notification.promotionId!);
    } else if (widget.onMerchantTap != null) {
      widget.onMerchantTap!(notification.merchantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(clientNotificationsStreamProvider);
    return _buildScaffold(context, notificationsAsync);
  }
}
