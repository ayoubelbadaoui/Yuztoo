import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../client_home/application/providers.dart';
import '../../client_notification/application/providers.dart';
import '../../followed_merchants/application/providers.dart'
    show setMuteStateProvider;
import '../../promotions/application/providers.dart' show recordPromoViewsProvider;
import '../../promotions/domain/entities/promotion.dart';

part 'notifications_screen.part.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onMerchantTap,
    this.onPromotionTap,
    this.onBonTap,
  });

  /// Called when a notification without a specific promotion is tapped.
  final void Function(String merchantId)? onMerchantTap;

  /// Called when a promotion notification with a promotionId is tapped.
  final void Function(String merchantId, String promotionId)? onPromotionTap;

  /// Called when a `bon_expiring` / `bon_expired` or [ClientNotificationType.loyalty]
  /// row is tapped. Consumers should route to "Mes avantages" (same as FCM
  /// for those types), including dual-profile role switching when applicable.
  final VoidCallback? onBonTap;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _activeTab = 'alertes'; // 'alertes' | 'promos'

  Future<void> _markAllRead() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    final useCase = ref.read(markAllNotificationsReadProvider);
    await useCase(authState.user.id);
  }

  Future<bool> _deleteOne(ClientNotification notification) async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return false;
    if (notification.id.isEmpty) return false;
    final result = await ref
        .read(deleteNotificationProvider)
        .call(authState.user.id, notification.id);
    if (!mounted) return false;
    return result.fold(
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible de supprimer cette alerte',
              style: merchantSnackBarTextOnWarmAccent(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        return false;
      },
      (_) => true,
    );
  }

  Future<void> _deleteAll() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.navyCard,
        title: Text(
          'Tout supprimer ?',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
        content: Text(
          'Toutes vos alertes seront définitivement supprimées.',
          style: GoogleFonts.outfit(
              fontSize: 14,
              color: MerchantColors.textLightGrey,
              height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.outfit(color: MerchantColors.gold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer tout',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(deleteAllNotificationsProvider)
        .call(authState.user.id);
    if (!mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de supprimer les alertes',
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      ),
      (_) {},
    );
  }

  Future<void> _handleTap(ClientNotification notification) async {
    // 1. Mark read fire-and-forget
    if (!notification.isRead) {
      final useCase = ref.read(markNotificationReadProvider);
      unawaited(useCase(notification.clientId, notification.id));
    }
    // 2. Deep-link navigation. Order matters:
    //    bon + loyalty types → Mes avantages (shell mirrors FCM routing)
    //    promotion → onPromotionTap when promotionId is set
    //    everything else → onMerchantTap to the storefront
    final isBonTap = notification.type == ClientNotificationType.bonExpiring ||
        notification.type == ClientNotificationType.bonExpired;
    final isLoyaltyTap = notification.type == ClientNotificationType.loyalty;
    if ((isBonTap || isLoyaltyTap) && widget.onBonTap != null) {
      widget.onBonTap!();
    } else if (notification.promotionId != null &&
        widget.onPromotionTap != null) {
      widget.onPromotionTap!(notification.merchantId, notification.promotionId!);
    } else if (widget.onMerchantTap != null) {
      widget.onMerchantTap!(notification.merchantId);
    }
  }

  void _setTab(String tab) => setState(() => _activeTab = tab);

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(clientNotificationsStreamProvider);
    final authState = ref.watch(authStateProvider);
    final isGuest = authState is! Authenticated;
    return _buildScaffold(context, notificationsAsync, isGuest);
  }
}
