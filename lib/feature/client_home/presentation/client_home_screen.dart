import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../promotions/domain/entities/promotion.dart';

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
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: Column(
                  children: [
                    _buildTagline(context),
                    feedAsync.when(
                      data: (feed) =>
                          _buildBusinessCard(context, feed.merchants),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderStronger),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MerchantColors.gold, width: 2),
                  color: MerchantColors.gold.withValues(alpha: 0.1),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_outline,
                  color: MerchantColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mon carnet Yuztoo',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onNavigate('notifications'),
                icon: Icon(
                  Icons.notifications_outlined,
                  color: MerchantColors.gold,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Text(
        'Tous les commerces que tu aimes au même endroit !',
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 15,
          height: 1.6,
          color: MerchantColors.textLightGrey,
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, List<Merchant> merchants) {
    if (merchants.isEmpty) {
      return _buildEmptyCarnet(context);
    }
    final merchant = merchants.first;
    final displayName = merchant.displayName ?? merchant.name;
    final imageUrl = merchant.bannerUrl ?? merchant.logoUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.favorite, color: MerchantColors.gold, size: 18),
                  const SizedBox(width: 4),
                  Icon(Icons.favorite, color: MerchantColors.gold, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MerchantColors.gold, width: 2),
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.star, color: MerchantColors.gold, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (onStoreSelect != null) {
                  onStoreSelect!(merchant.id);
                } else {
                  onNavigate('store-profile');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: MerchantColors.gold,
                side: const BorderSide(color: MerchantColors.gold, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Bienvenue sur Yuztoo',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MerchantColors.gold,
            MerchantColors.cream,
          ],
        ),
      ),
      child: Center(
        child: Text(
          'Image commerce',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: MerchantColors.textGrey,
          ),
        ),
      ),
    );
  }

  /// Clear loading state: no fake card or dummy text, avoids flash on app open.
  Widget _buildBusinessCardLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MerchantColors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chargement...',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textLightGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCarnet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.stores,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  color: MerchantColors.gold.withValues(alpha: 0.7),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Suivez des commerces pour voir ici leurs offres, promotions et actualités.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: MerchantColors.textLightGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scanne un QR code ou découvre des commerces.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: MerchantColors.textGrey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onNavigate('qr-scanner'),
                      icon: const Icon(Icons.qr_code_scanner, color: MerchantColors.gold, size: 20),
                      label: Text(
                        AppLocalizations.of(context)!.scan,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.gold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: MerchantColors.gold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => onNavigate('discovery'),
                      icon: const Icon(Icons.explore_outlined, color: MerchantColors.gold, size: 20),
                      label: Text(
                        'Découvrir',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.gold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: MerchantColors.gold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderAlpha),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _QuickAction(
              icon: Icons.qr_code_rounded,
              label: l10n.scan,
              onTap: () => onNavigate('qr-scanner'),
            ),
            _QuickAction(
              icon: Icons.star_border,
              label: l10n.loyaltyLabel,
              onTap: () => onNavigate('loyalty'),
            ),
            _QuickAction(
              icon: Icons.card_giftcard_outlined,
              label: l10n.offers,
              onTap: () => onNavigate('discovery'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsContent(
    BuildContext context,
    List<Promotion> promotions,
    List<Merchant> merchants,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final merchantNames = {
      for (final m in merchants) m.id: (m.displayName ?? m.name),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activePromotions,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate('discovery'),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (promotions.isEmpty)
            Text(
              'Aucune promotion pour le moment',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
              ),
            )
          else
            Column(
              children: promotions
                  .map((promo) => _buildPromoRow(
                        context,
                        promo,
                        merchantNames[promo.merchantId] ?? promo.subtitle,
                        promo.merchantId,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPromotionsLoading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activePromotions,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate('discovery'),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 24,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MerchantColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsError(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activePromotions,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate('discovery'),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune promotion',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoRow(
    BuildContext context,
    Promotion promo,
    String storeName,
    String? merchantId,
  ) {
    final now = DateTime.now();
    final daysLeft = promo.dateTo.isAfter(now)
        ? promo.dateTo.difference(now).inDays
        : 0;
    final expiresText = daysLeft > 0 ? '$daysLeft jours' : 'Expiré';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (merchantId != null && onStoreSelect != null) {
              onStoreSelect!(merchantId);
            } else {
              onNavigate('store-profile');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_offer_outlined,
                    color: MerchantColors.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storeName.isNotEmpty ? storeName : promo.subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: MerchantColors.textLightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    expiresText,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MerchantColors.gold, width: 2),
              color: MerchantColors.gold.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: MerchantColors.gold, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ],
      ),
    );
  }
}
