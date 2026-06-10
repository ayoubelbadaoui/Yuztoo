import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/application/precache_network_images.dart';
import '../../auth/core/application/providers.dart' show authStateProvider;
import '../../auth/core/application/state/auth_state.dart' show Authenticated;
import '../../merchant_partners/application/providers.dart'
    as partners_providers;
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../promotions/application/providers.dart'
    show recordPromoViewsProvider;
import '../../promotions/domain/entities/promotion.dart';
import '../../storefront/application/profile_view_providers.dart';
import '../../storefront/domain/entities/business_hours.dart';
import '../../storefront/application/widgets.dart';
import '../../loyalty/application/client_loyalty_providers.dart'
    show clientLoyaltyFeedProvider;
import '../application/providers.dart';
import 'widgets/store_profile_banner_section.dart';

part 'store_profile_screen.part.dart';

// ── Skeleton loading screen ────────────────────────────────────────────────────

class _StoreProfileSkeleton extends StatefulWidget {
  const _StoreProfileSkeleton({required this.onBack});
  final VoidCallback onBack;

  @override
  State<_StoreProfileSkeleton> createState() => _StoreProfileSkeletonState();
}

class _StoreProfileSkeletonState extends State<_StoreProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _shimmer(double w, double h, {double radius = 8}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E0D0),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner placeholder
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => Opacity(
                  opacity: _anim.value,
                  child: Container(
                    height: 180 + top,
                    color: const Color(0xFFE8E0D0),
                  ),
                ),
              ),
              const SizedBox(height: 56),
              // Name + hearts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _shimmer(160, 22, radius: 6),
                        const Spacer(),
                        _shimmer(72, 22, radius: 6),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _shimmer(100, 14, radius: 6),
                    const SizedBox(height: 12),
                    _shimmer(80, 26, radius: 13),
                    const SizedBox(height: 20),
                    _shimmer(double.infinity, 52, radius: 14),
                    const SizedBox(height: 16),
                    _shimmer(double.infinity, 46, radius: 14),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _shimmer(double.infinity, 14, radius: 6),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmer(80, 11, radius: 4),
                    const SizedBox(height: 10),
                    _shimmer(180, 16, radius: 6),
                    const SizedBox(height: 16),
                    _shimmer(80, 11, radius: 4),
                    const SizedBox(height: 10),
                    _shimmer(220, 16, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Back button still works during loading
        Positioned(
          top: top + 8,
          left: 12,
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Client-facing store profile. Light Vitrine-style (cream background, same banner/logo layout as merchant storefront).
class StoreProfileScreen extends ConsumerStatefulWidget {
  const StoreProfileScreen({
    super.key,
    required this.onBack,
    this.onNotifications,
    this.onMessage,
    this.onReserve,
    this.onRequestLogin,
  });

  static String get path => '/store-profile';

  final VoidCallback onBack;
  final VoidCallback? onNotifications;
  final VoidCallback? onMessage;
  final VoidCallback? onReserve;

  /// Called when a guest tries a loyalty or follow action that requires sign-in.
  final VoidCallback? onRequestLogin;

  @override
  ConsumerState<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends ConsumerState<StoreProfileScreen> {
  String _activeTab = 'accueil';
  bool _isFollowToggling = false;
  String? _optimisticHeartMerchantId;
  int? _optimisticHeartLevel;
  int _heartSaveToken = 0;
  String? _lastViewedKey;

  /// Prevents re-firing the QR/NFC arrival funnel on rebuild within one visit.
  bool _scanArrivalHandled = false;

  /// Prevents re-opening the promotion detail sheet on rebuild after a
  /// notification-tap deep-link is consumed.
  bool _promotionDeepLinkHandled = false;

  /// Avoids showing the welcome-gift modal twice (follow-then-passage).
  String? _welcomeShownForMerchantId;

  /// "viewerUid::merchantId" of the last (viewer, merchant) pair for which
  /// we have already fired a profile-view record. Prevents re-firing on
  /// every rebuild of the same screen instance — the repo is also
  /// idempotent server-side (1 doc per viewer/UTC day), but this avoids
  /// even the no-op network round-trip on each frame.
  String? _profileViewRecordedFor;

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(storeProfilePageDataProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // Status bar sits over the banner — transparent so the image shows
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        // Bottom nav is dark navy
        systemNavigationBarColor: StorefrontColors.navyDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: StorefrontColors.backgroundLight,
        body: pageAsync.when(
          data: (data) {
            final merchant = data.merchant;
            if (merchant == null) {
              return _StoreProfileErrorBack(onBack: widget.onBack);
            }
            // Guard: inactive merchants must not show a full storefront to
            // clients who arrive via QR / deep link / saved follows.
            // Discovery already hides them; this closes the direct-ID path.
            if (merchant.status != 'active') {
              return _StoreProfileOffline(
                merchantName: merchant.name,
                onBack: widget.onBack,
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              precacheHttpImages(context, [
                merchant.bannerUrl,
                merchant.logoUrl,
                ...?merchant.newsImageUrls,
              ]);
              _recordProfileViewIfNeeded(merchant.id);
            });
            return _buildContent(context, merchant, data.promotions);
          },
          loading: () => _StoreProfileSkeleton(onBack: widget.onBack),
          error: (_, __) => _StoreProfileErrorBack(onBack: widget.onBack),
        ),
      ),
    );
  }

  void _onTabChanged(String tab) {
    setState(() => _activeTab = tab);
  }

  void _setFollowToggling(bool value) {
    setState(() => _isFollowToggling = value);
  }

  /// Fire-and-forget profile-view recording. Called from the post-frame
  /// callback of [build] so it runs once per frame after the storefront
  /// is actually painted. Multiple guards keep the write footprint
  /// minimal and align with the user's expectation that "vues de profil"
  /// counts genuine inbound traffic:
  ///
  /// * skip when [merchantId] is empty,
  /// * skip anonymous / guest visitors (no Firestore auth → no rule
  ///   match anyway),
  /// * skip the merchant viewing their own preview (would inflate),
  /// * skip if we've already recorded this (viewer, merchant) pair for
  ///   the current screen instance — the repo is also day-idempotent,
  ///   but this avoids even the no-op round-trip on every rebuild.
  void _recordProfileViewIfNeeded(String merchantId) {
    if (merchantId.isEmpty) return;
    final viewerId = ref.read(currentUserIdProvider);
    if (viewerId == null || viewerId.isEmpty) return;
    if (viewerId == merchantId) return;
    final key = '$viewerId::$merchantId';
    if (_profileViewRecordedFor == key) return;
    _profileViewRecordedFor = key;
    final record = ref.read(recordProfileViewProvider);
    unawaited(record(merchantId: merchantId, viewerId: viewerId));
  }

  /// Single source of truth for the follow / unfollow toggle. Used by both
  /// the top "Suivre" CTA AND the discreet bottom "Ne plus suivre" link, so
  /// the auth-gate, snackbar, and undo flow stay identical regardless of
  /// which entry point the user tapped.
  Future<void> _handleFollowToggle({
    required BuildContext context,
    required Merchant merchant,
    required bool currentlyFollowing,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final merchantId = merchant.id;
    if (userId == null) {
      final merchantName = merchant.displayName?.isNotEmpty == true
          ? merchant.displayName!
          : merchant.name;
      _showAuthGateSheet(
        context,
        merchant,
        message:
            'Connectez-vous pour suivre $merchantName et rester informé de ses actualités et promotions.',
      );
      return;
    }
    _setFollowToggling(true);
    final toggleFollow = ref.read(toggleMerchantFollowProvider);
    final result = await toggleFollow.call(
      userId: userId,
      merchantId: merchantId,
      currentlyFollowing: currentlyFollowing,
    );
    if (!context.mounted) return;
    _setFollowToggling(false);
    if (result.isLeft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de la sauvegarde'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.invalidate(followedMerchantIdsForCurrentUserProvider);
    ref.invalidate(followedMerchantHeartLevelsForCurrentUserProvider);
    ref.invalidate(clientHomeFeedProvider);
    ref.invalidate(discoveryMerchantsProvider);
    ref.invalidate(discoveryRecommendedMerchantsProvider);
    ref.invalidate(discoveryFollowedMerchantsProvider);
    // Refresh the "X abonnés" pill on this vitrine so the count reflects
    // the new follow/unfollow immediately.
    ref.invalidate(followersCountByMerchantIdsProvider(<String>[merchantId]));
    if (!context.mounted) return;

    // Fresh follow → reveal the merchant's welcome gift, scan-or-no-scan.
    // The post-scan modal that used to do this was removed in the NFC MVP
    // (see [_showScanFollowFirstSheet] legacy comment), so the only
    // remaining trigger for the welcome sheet is the regular Suivre CTA.
    if (!currentlyFollowing) {
      _afterScanFollowSuccess(context, merchant, userId);
    }
    // `currentlyFollowing` is the state BEFORE the toggle, so when it was
    // true we just unfollowed. Offer a 5-second undo on the unfollow path —
    // fat-finger taps are the most common support ticket on this button
    // and a re-follow round-trip is otherwise friction-heavy (it also
    // re-fires the welcome bon flow on some merchants).
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: currentlyFollowing
            ? const Duration(seconds: 5)
            : const Duration(seconds: 2),
        content: Text(
          currentlyFollowing
              ? 'Commerce retiré de votre carnet'
              : 'Commerce ajouté à votre carnet ✓',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: StorefrontColors.primaryGold,
        action: currentlyFollowing
            ? SnackBarAction(
                label: 'Annuler',
                textColor: StorefrontColors.navyDark,
                onPressed: () async {
                  if (!context.mounted) return;
                  _setFollowToggling(true);
                  final undo = await toggleFollow.call(
                    userId: userId,
                    merchantId: merchantId,
                    // Currently NOT following (we just unfollowed), so re-follow.
                    currentlyFollowing: false,
                  );
                  if (!context.mounted) return;
                  _setFollowToggling(false);
                  if (undo.isRight) {
                    ref.invalidate(followedMerchantIdsForCurrentUserProvider);
                    ref.invalidate(
                        followedMerchantHeartLevelsForCurrentUserProvider);
                    ref.invalidate(clientHomeFeedProvider);
                    ref.invalidate(followersCountByMerchantIdsProvider(
                        <String>[merchantId]));
                  }
                },
              )
            : null,
      ),
    );
  }

  Future<void> _setHeartLevel(
    BuildContext context, {
    required String? userId,
    required String merchantId,
    required int level,
  }) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connectez-vous pour enregistrer vos favoris'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Se connecter',
            textColor: StorefrontColors.primaryGold,
            onPressed: () => widget.onRequestLogin?.call(),
          ),
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final token = ++_heartSaveToken;
    setState(() {
      _optimisticHeartMerchantId = merchantId;
      _optimisticHeartLevel = level.clamp(0, 3);
    });
    final ensureHeart = ref.read(ensureFollowedAndSetHeartLevelProvider);
    final heartResult = await ensureHeart.call(
      userId: userId,
      merchantId: merchantId,
      heartLevel: level,
    );
    if (token != _heartSaveToken) return;
    if (!context.mounted) return;
    if (heartResult.isLeft) {
      setState(() {
        _optimisticHeartMerchantId = null;
        _optimisticHeartLevel = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de la sauvegarde du favori'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.invalidate(followedMerchantIdsForCurrentUserProvider);
    ref.invalidate(followedMerchantHeartLevelsForCurrentUserProvider);
    ref.invalidate(clientHomeFeedProvider);
    // ensureFollowedAndSetHeartLevel also creates a follow when the user
    // hadn't followed yet — refresh the storefront's "X abonnés" pill so
    // the count reflects the new follower immediately.
    ref.invalidate(followersCountByMerchantIdsProvider(<String>[merchantId]));
    // Keep UI instant and quiet; no success snackbar on every tap.
  }
}
