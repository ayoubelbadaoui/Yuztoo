import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../../core/shared/widgets/yuztoo_gradient_title.dart';
import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../../core/shared/widgets/yuztoo_pull_refresh.dart';
import '../../client_home/application/providers.dart';
import '../../discovery/application/providers.dart'
    show discoveryCityMerchantsProvider;
import '../../notifications/application/providers.dart';
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
  String _activeTab = 'alertes'; // 'alertes' | 'promos' | 'ville'
  final Map<String, GlobalKey> _notificationRowKeys = <String, GlobalKey>{};

  Future<void> _onPullRefresh() async {
    ref.invalidate(clientNotificationsStreamProvider);
    ref.invalidate(clientHomePromotionsProvider);
    ref.invalidate(clientCityPromotionsProvider);
    ref.invalidate(clientHomeFeedProvider);
    ref.invalidate(discoveryCityMerchantsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

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
    //    everything else → detail sheet (full content), storefront one tap away
    final isBonTap = notification.type == ClientNotificationType.bonExpiring ||
        notification.type == ClientNotificationType.bonExpired;
    final isLoyaltyTap = notification.type == ClientNotificationType.loyalty;
    if ((isBonTap || isLoyaltyTap) && widget.onBonTap != null) {
      widget.onBonTap!();
    } else if (notification.type == ClientNotificationType.promotion &&
        notification.promotionId != null &&
        notification.promotionId!.isNotEmpty &&
        widget.onPromotionTap != null) {
      widget.onPromotionTap!(notification.merchantId, notification.promotionId!);
    } else {
      // "quand un client clique sur une notification il veut voir la
      // notification, pas repartir sur la vitrine" — generic rows (rappels
      // auto, anniversaires…) open the full content in place. The list rows
      // truncate title/body, so this sheet is where the message is actually
      // readable; the storefront remains reachable via the secondary CTA.
      _showNotificationDetailSheet(notification);
    }
  }

  /// Full-content detail for a generic notification. Mirrors the inbox's
  /// dark visual language; "Voir la boutique" is the secondary action so
  /// reading the message stays the primary outcome of the tap.
  void _showNotificationDetailSheet(ClientNotification notification) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MerchantColors.bgHeader,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                notification.merchantName,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.gold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                notification.title,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.textWhite,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    notification.body,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: MerchantColors.textLightGrey,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
              if (widget.onMerchantTap != null &&
                  notification.merchantId.isNotEmpty) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      widget.onMerchantTap!(notification.merchantId);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: MerchantColors.gold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Voir la boutique',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MerchantColors.bgMain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _setTab(String tab) => setState(() => _activeTab = tab);

  /// Applies tab + scroll intent from [NotificationInboxDeepLink]. Caller must
  /// clear the provider before calling, or pass a copy (FCM sets the provider
  /// before this route mounts — [ref.listen] alone would miss that).
  void _applyInboxDeepLink(NotificationInboxDeepLink link) {
    final tab = link.initialTab;
    final scrollId = link.notificationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (tab == 'promos' || tab == 'alertes' || tab == 'ville') {
          _activeTab = tab;
        }
      });
      if (scrollId != null && scrollId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final ctx = _notificationRowKeys[scrollId]?.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(ctx, alignment: 0.15);
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Consume a link set by the shell in the same frame *before* this widget
    // subscribed — ref.listen only sees subsequent changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(notificationInboxDeepLinkProvider);
      if (pending == null) return;
      ref.read(notificationInboxDeepLinkProvider.notifier).state = null;
      _applyInboxDeepLink(pending);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationInboxDeepLinkProvider, (previous, next) {
      if (next == null || !mounted) return;
      ref.read(notificationInboxDeepLinkProvider.notifier).state = null;
      _applyInboxDeepLink(next);
    });

    final notificationsAsync = ref.watch(clientNotificationsStreamProvider);
    final authState = ref.watch(authStateProvider);
    final isGuest = authState is! Authenticated;
    return _buildScaffold(context, notificationsAsync, isGuest);
  }
}
