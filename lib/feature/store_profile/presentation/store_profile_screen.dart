import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/application/precache_network_images.dart';
import '../../loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant_partners/application/providers.dart' as partners_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../promotions/application/providers.dart' show recordPromoViewsProvider;
import '../../promotions/domain/entities/promotion.dart';
import '../../storefront/domain/entities/business_hours.dart';
import '../../storefront/application/widgets.dart';
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
  });

  static String get path => '/store-profile';

  final VoidCallback onBack;
  final VoidCallback? onNotifications;
  final VoidCallback? onMessage;
  final VoidCallback? onReserve;

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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              precacheHttpImages(context, [
                merchant.bannerUrl,
                merchant.logoUrl,
                ...?merchant.newsImageUrls,
              ]);
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

  Future<void> _setHeartLevel(
    BuildContext context, {
    required String? userId,
    required String merchantId,
    required int level,
  }) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour enregistrer vos favoris'),
          behavior: SnackBarBehavior.floating,
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
    // Keep UI instant and quiet; no success snackbar on every tap.
  }

}
