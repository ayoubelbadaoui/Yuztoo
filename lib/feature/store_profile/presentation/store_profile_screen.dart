import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/application/precache_network_images.dart';
import '../../loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../promotions/domain/entities/promotion.dart';
import '../../storefront/domain/entities/business_hours.dart';
import '../../storefront/application/widgets.dart';
import '../application/providers.dart';
import 'widgets/store_profile_banner_section.dart';

part 'store_profile_screen.part.dart';

/// Client-facing store profile. Light Vitrine-style (cream background, same banner/logo layout as merchant storefront).
class StoreProfileScreen extends ConsumerStatefulWidget {
  const StoreProfileScreen({
    super.key,
    required this.onBack,
    required this.onNotifications,
    required this.onMessage,
    required this.onReserve,
  });

  static String get path => '/store-profile';

  final VoidCallback onBack;
  final VoidCallback onNotifications;
  final VoidCallback onMessage;
  final VoidCallback onReserve;

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
        statusBarColor: StorefrontColors.backgroundLight,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: StorefrontColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
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
          loading: () => const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: StorefrontColors.primaryGold,
                strokeWidth: 2,
              ),
            ),
          ),
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
