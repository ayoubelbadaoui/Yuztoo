import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/app_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/carnet_merchant_order.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../promotions/domain/entities/promotion.dart';


part 'client_home_screen.part.dart';

/// Client Accueil – "Mon carnet Yuztoo". Shows real merchants from the database.
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({
    super.key,
    required this.onNavigate,
    this.onStoreSelect,
    this.isDualProfile = false,
  });

  static String get path => '/client-home';

  final ValueChanged<String> onNavigate;
  /// When user taps a business, call with merchant id so store profile loads that merchant.
  final ValueChanged<String>? onStoreSelect;
  /// True when this user also has a merchant account — shows the switch-to-merchant icon.
  final bool isDualProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(clientHomeFeedProvider);
    final heartLevelsAsync =
        ref.watch(followedMerchantHeartLevelsForCurrentUserProvider);
    final hasProAccount = ref
            .watch(merchant_providers.hasLinkedMerchantAccountProvider)
            .valueOrNull ??
        isDualProfile;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context, showMerchantSwitch: hasProAccount),
            Expanded(
              child: RefreshIndicator(
                color: MerchantColors.gold,
                backgroundColor: MerchantColors.bgHeader,
                onRefresh: () async {
                  ref.invalidate(clientHomeFeedProvider);
                  ref.invalidate(followedMerchantIdsForCurrentUserProvider);
                  ref.invalidate(followedMerchantHeartLevelsForCurrentUserProvider);
                  await ref.read(clientHomeFeedProvider.future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    children: [
                      _buildTagline(context),
                      feedAsync.when(
                        data: (feed) => _buildBusinessCard(
                          context,
                          ref,
                          feed.merchants,
                          heartLevelsAsync.valueOrNull ?? const <String, int>{},
                          followedIds: feed.followedIds,
                          ownMerchantId: feed.ownMerchantId,
                        ),
                        loading: () => _buildBusinessCardLoading(context),
                        error: (e, _) => _buildBusinessCardError(context, ref),
                      ),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      feedAsync.when(
                        data: (feed) => _buildPromotionsContent(
                          context,
                          feed.promotions,
                          feed.merchants,
                        ),
                        loading: () => _buildPromotionsLoading(context),
                        error: (_, __) => _buildPromotionsError(context),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
