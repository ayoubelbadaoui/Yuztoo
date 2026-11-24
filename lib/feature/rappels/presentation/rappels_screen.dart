import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/coachmark_tour.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../../core/shared/widgets/yuztoo_pull_refresh.dart';
import '../../loyalty/application/active_validation_providers.dart';
import '../../loyalty/presentation/widgets/reward_redemption_section.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../../storefront/domain/entities/storefront.dart';
import '../application/providers.dart' as rappels_providers;
import 'widgets/pending_clients_section.dart';
import 'widgets/notifications_auto_entry.dart';
import 'widgets/quick_send_section.dart';
// Kept while RappelsProductSection is hidden (see rappels_screen.part.dart)
// so re-enabling the NFC plaque marketing block is a single-line revert.
// ignore: unused_import
import 'widgets/rappels_product_section.dart';
import '../../../core/shared/widgets/yuztoo_tab_header.dart';

part 'rappels_screen.part.dart';

/// Notifications screen – quick send, pending clients, auto-notif entry.
/// Auto-validation toggles live under Vos clients → Validation.
class RappelsScreen extends ConsumerStatefulWidget {
  final void Function(String)? onNavigate;
  final VoidCallback? onBack;

  const RappelsScreen({super.key, this.onNavigate, this.onBack});

  @override
  ConsumerState<RappelsScreen> createState() => _RappelsScreenState();
}

class _RappelsScreenState extends ConsumerState<RappelsScreen> {
  bool _guideScheduled = false;

  // Coachmark anchors for the page guide.
  final QuickSendGuideKeys _quickKeys = QuickSendGuideKeys();
  final GlobalKey _rewardsKey = GlobalKey();
  final GlobalKey _pendingKey = GlobalKey();
  final GlobalKey _autoKey = GlobalKey();
  CoachmarkTourHandle? _tour;

  /// Shown once per device (replaces the old « Comment ça marche ? » popup);
  /// the small ⓘ in the header replays it.
  static const String _guideSeenKey = 'coach_rappels_page_seen_v1';

  @override
  void dispose() {
    _tour?.dismiss();
    super.dispose();
  }

  void _scheduleGuideOnce() {
    if (_guideScheduled) return;
    _guideScheduled = true;
    unawaited(_maybeShowGuideOnce());
  }

  Future<void> _maybeShowGuideOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_guideSeenKey) ?? false) return;
      await prefs.setBool(_guideSeenKey, true);
    } on Object {
      return;
    }
    // Let sections (history, rewards…) finish their first layout.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _showPageGuide();
  }

  void _showPageGuide() {
    _tour?.dismiss();
    _tour = CoachmarkTour.show(
      context,
      steps: [
        CoachmarkStep(
          targetKey: _quickKeys.compose,
          icon: Icons.send_rounded,
          title: 'Envoyez un message à vos clients',
          message: 'Écrivez ici une notification : promo, nouveauté, '
              'événement… Elle arrive directement sur le téléphone de '
              'vos clients.',
        ),
        CoachmarkStep(
          targetKey: _quickKeys.templates,
          icon: Icons.bookmark_outline_rounded,
          title: 'Vos modèles',
          message: '« Enregistrer » garde le message pour plus tard. '
              '« Charger un template » le réutilise en un geste.',
        ),
        CoachmarkStep(
          targetKey: _quickKeys.audience,
          icon: Icons.groups_rounded,
          title: 'À qui l’envoyer',
          message: 'Tous vos clients, ou seulement certains : nouveaux, '
              'habitués, VIP, inactifs…',
        ),
        CoachmarkStep(
          targetKey: _quickKeys.quota,
          icon: Icons.speed_rounded,
          title: 'Votre quota',
          message: 'Le nombre d’envois possibles cette semaine. Il se '
              'recharge chaque semaine.',
        ),
        CoachmarkStep(
          targetKey: _quickKeys.schedule,
          icon: Icons.schedule_rounded,
          title: 'Programmer plus tard',
          message: 'Choisissez une date et une heure : la notification '
              'partira toute seule à ce moment-là.',
        ),
        CoachmarkStep(
          targetKey: _quickKeys.send,
          icon: Icons.rocket_launch_outlined,
          title: 'Envoyer',
          message: 'Envoie tout de suite (ou programme, si vous avez choisi '
              'une heure). Une confirmation indique combien de clients '
              'l’ont reçue.',
        ),
        CoachmarkStep(
          targetKey: _quickKeys.scheduled,
          icon: Icons.event_note_rounded,
          title: 'Vos envois programmés',
          message: 'Les notifications en attente apparaissent ici. Vous '
              'pouvez annuler un envoi avant son heure.',
        ),
        CoachmarkStep(
          targetKey: _quickKeys.history,
          icon: Icons.history_rounded,
          title: 'Historique',
          message: 'Tous vos messages déjà envoyés, avec leur date.',
        ),
        CoachmarkStep(
          targetKey: _rewardsKey,
          icon: Icons.card_giftcard_rounded,
          title: 'Récompenses à remettre',
          message: 'Les clients qui ont gagné une récompense fidélité. '
              'Remettez-la en magasin puis validez-la ici.',
        ),
        CoachmarkStep(
          targetKey: _pendingKey,
          icon: Icons.person_add_alt_1_rounded,
          title: 'Nouveaux clients',
          message: 'Les clients qui ont scanné votre QR code et attendent '
              'votre accord.',
        ),
        CoachmarkStep(
          targetKey: _autoKey,
          icon: Icons.auto_awesome_rounded,
          title: 'Notifications automatiques',
          message: 'Pour les messages qui partent tout seuls (anniversaire, '
              'nouveau client, client inactif…). Un guide vous y attend aussi.',
        ),
      ],
      onFinish: () => _tour = null,
    );
  }

  Future<void> _onQuickSend(
    String text,
    String audience,
    List<String> segments,
  ) async {
    final merchant = ref
        .read(merchant_providers.currentMerchantForOwnerProvider)
        .valueOrNull;
    if (merchant == null) return;
    final useCase =
        ref.read(rappels_providers.sendMerchantNotificationProvider);
    final result = await useCase.call(
      merchantId: merchant.id,
      merchantName: merchant.name,
      text: text,
      audience: audience,
      segments: segments,
      callerUid: merchant.ownerUid,
    );
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l\'envoi',
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.red[400],
        ),
      ),
      (sent) {
        ref.invalidate(
            rappels_providers.sentNotificationsProvider(merchant.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification envoyée à $sent client${sent > 1 ? 's' : ''}',
              style: merchantSnackBarTextOnGold(),
            ),
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
    );
  }

  Future<void> _onPullRefresh() async {
    final merchant = ref
        .read(merchant_providers.currentMerchantForOwnerProvider)
        .valueOrNull;
    ref.invalidate(storefront_providers.storefrontProvider);
    ref.invalidate(merchant_providers.currentMerchantForOwnerProvider);
    if (merchant != null) {
      ref.invalidate(rappels_providers.sentNotificationsProvider(merchant.id));
      ref.invalidate(
          rappels_providers.pendingClientsForMerchantProvider(merchant.id));
      ref.invalidate(rappels_providers.rappelsAlertsProvider(merchant.id));
      ref.invalidate(merchantActiveValidationQueueProvider);
    }
    await ref
        .read(storefront_providers.storefrontProvider.future)
        .catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefront_providers.storefrontProvider);
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final Merchant? merchant = merchantAsync.valueOrNull;
    if (merchant != null) {
      _scheduleGuideOnce();
    }

    return _buildRappelsScaffold(
      context,
      storefrontAsync: storefrontAsync,
      merchantAsync: merchantAsync,
      merchant: merchant,
    );
  }
}
