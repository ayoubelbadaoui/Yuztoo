import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../promotions/domain/entities/promotion.dart';


part 'client_home_screen.part.dart';

/// Client Accueil – "Mon carnet Yuztoo". Shows real merchants from the database.
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({
    super.key,
    required this.onNavigate,
    this.onStoreSelect,
  });

  static String get path => '/client-home';

  final ValueChanged<String> onNavigate;
  /// When user taps a business, call with merchant id so store profile loads that merchant.
  final ValueChanged<String>? onStoreSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(clientHomeFeedProvider);
    final heartLevelsAsync =
        ref.watch(followedMerchantHeartLevelsForCurrentUserProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context),
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
                          feed.merchants,
                          heartLevelsAsync.valueOrNull ?? const <String, int>{},
                          followedIds:
                              feed.merchants.map((m) => m.id).toList(),
                        ),
                        loading: () => _buildBusinessCardLoading(context),
                        error: (_, __) => _buildBusinessCardLoading(context),
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
