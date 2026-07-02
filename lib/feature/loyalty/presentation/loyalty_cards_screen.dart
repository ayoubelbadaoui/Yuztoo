import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/app_logo.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../auth/core/application/user_display_helpers.dart';
import '../../../core/shared/widgets/yuztoo_pull_refresh.dart';
import '../../storefront/presentation/widgets/storefront_colors.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart'
    show LoyaltyRewardKind;
import '../application/loyalty_reward_category.dart';
import '../application/providers.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart'
    show ClientLoyaltyTier;
import 'widgets/client_validation_banner.dart';

part 'loyalty_cards_screen.part.dart';

/// Client fidélité — real per-merchant loyalty cards backed by Firestore.
class LoyaltyCardsScreen extends ConsumerStatefulWidget {
  const LoyaltyCardsScreen({
    super.key,
    required this.onBack,
    required this.onNotifications,
    required this.onScan,
    this.onSwitchToMerchant,
    this.onStoreTap,
  });

  static String get path => '/loyalty';

  final VoidCallback onBack;
  final VoidCallback onNotifications;

  /// Opens the QR/NFC scanner. Passage validation is scan-only ("cela ne
  /// doit pas être possible de valider un passage sans avoir scanné le code
  /// ou le NFC du commerçant") — the FAB therefore routes to the scanner
  /// instead of the legacy BLE broadcast path.
  final VoidCallback onScan;

  /// Non-null when the user has both client and merchant roles.
  /// Shown as a storefront icon in the header so dual-profile users can
  /// switch back to merchant shell without going through the profile tab.
  final VoidCallback? onSwitchToMerchant;

  /// Called with merchant id when the user taps a loyalty card.
  final ValueChanged<String>? onStoreTap;

  @override
  ConsumerState<LoyaltyCardsScreen> createState() => _LoyaltyCardsScreenState();
}

class _LoyaltyCardsScreenState extends ConsumerState<LoyaltyCardsScreen> {
  LoyaltyRewardCategory _category = LoyaltyRewardCategory.purchaseVoucher;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final authState = ref.watch(authStateProvider);

    if (authState is! Authenticated) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Center(
            child: Text(
              'Connectez-vous pour voir votre fidélité.',
              style: GoogleFonts.outfit(color: MerchantColors.textLightGrey),
            ),
          ),
        ),
      );
    }

    final user = authState.user;
    final basics = ref.watch(userProfileBasicsProvider(user.id)).valueOrNull;
    final firstName = resolveDisplayName(user, basics).split(' ').first;
    final feedAsync = ref.watch(clientLoyaltyFeedProvider);
    final rewardsAsync = ref.watch(availableClientRewardsProvider);
    final entries = feedAsync.valueOrNull ?? const <ClientLoyaltyEntry>[];
    final rewards = rewardsAsync.valueOrNull ?? const <ClientRewardItem>[];

    final feedCounts = {
      for (final c in kLoyaltyRewardCategories)
        c: entries.where((e) => c.matchesConfig(e.config)).length,
    };
    final rewardCounts = {
      for (final c in kLoyaltyRewardCategories)
        c: rewards.where((r) => _rewardMatchesCategory(r, c)).length,
    };

    // Defer the "Type de fidélité" filter until the carnet has actual
    // diversity. New clients (zero cards or all cards in one type) get
    // a single, undivided list of merchants — the user feedback was
    // exactly "trop tôt … les clients se perdent … qu'ils voient tous
    // leurs commerçants au début". The filter chips reappear naturally
    // the moment the carnet contains 2+ reward kinds.
    final stillLoading = feedAsync.isLoading || rewardsAsync.isLoading;
    final representedCategoryCount = stillLoading
        ? 0
        : kLoyaltyRewardCategories
            .where((c) =>
                (feedCounts[c] ?? 0) > 0 || (rewardCounts[c] ?? 0) > 0)
            .length;
    final showCategoryFilter = representedCategoryCount >= 2;
    final effectiveCategory = showCategoryFilter ? _category : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: MerchantColors.bgHeader,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: MerchantColors.bgHeader,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: widget.onScan,
            backgroundColor: StorefrontColors.primaryGold,
            foregroundColor: StorefrontColors.navyDark,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              'Scanner',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            children: [
              _Header(
                onNotifications: widget.onNotifications,
                onSwitchToMerchant: widget.onSwitchToMerchant,
              ),
              Expanded(
                child: YuztooPullRefresh(
                  onRefresh: () async {
                    ref.invalidate(clientLoyaltyFeedProvider);
                    ref.invalidate(availableClientRewardsProvider);
                    await ref
                        .read(clientLoyaltyFeedProvider.future)
                        .catchError((_) => const <ClientLoyaltyEntry>[]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 88),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GreetingBlock(
                        firstName: firstName,
                        feedAsync: feedAsync,
                      ),
                      const SizedBox(height: 20),
                      if (showCategoryFilter) ...[
                        _LoyaltyCategoryFilterBar(
                          selected: _category,
                          feedCounts: feedAsync.isLoading
                              ? {
                                  for (final c in kLoyaltyRewardCategories) c: 0,
                                }
                              : feedCounts,
                          rewardCounts: rewardsAsync.isLoading
                              ? {
                                  for (final c in kLoyaltyRewardCategories) c: 0,
                                }
                              : rewardCounts,
                          onSelected: (c) => setState(() => _category = c),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _MesAvantagesSection(category: effectiveCategory),
                      _LoyaltyFeed(
                        category: effectiveCategory,
                        feedAsync: feedAsync,
                        onStoreTap: widget.onStoreTap,
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
