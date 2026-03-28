import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/presentation/precache_network_images.dart';
import '../../../feature/auth/core/application/providers.dart' as auth_providers;
import '../../../feature/client_home/application/providers.dart' as client_home_providers;
import '../../../feature/followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../../feature/merchant/domain/entities/merchant.dart';
import '../../../feature/promotions/domain/entities/promotion.dart';
import '../../../feature/storefront/domain/entities/business_hours.dart';
import '../../../feature/storefront/presentation/widgets/navigation_tabs.dart';
import '../../../feature/storefront/presentation/widgets/news_section.dart';
import '../../../feature/storefront/presentation/widgets/storefront_colors.dart';
import 'widgets/store_profile_banner_section.dart';
import '../application/providers.dart';

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
              return _buildErrorBack(context);
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
          error: (_, __) => _buildErrorBack(context),
        ),
      ),
    );
  }

  Widget _buildErrorBack(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Commerce introuvable',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: StorefrontColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: StorefrontColors.primaryGold),
            label: Text(
              'Retour',
              style: GoogleFonts.outfit(
                color: StorefrontColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Merchant merchant,
    List<Promotion> promotions,
  ) {
    final name = merchant.displayName ?? merchant.name;
    final activity = merchant.categories?.isNotEmpty == true
        ? merchant.categories!.join(', ')
        : (merchant.city.isNotEmpty ? merchant.city : 'Commerçant');
    final hours = merchant.hours != null && merchant.hours!.isNotEmpty
        ? BusinessHours.fromMap(merchant.hours)
        : null;
    final userId = ref.watch(auth_providers.currentUserIdProvider);
    final followedIdsAsync =
        ref.watch(client_home_providers.followedMerchantIdsForCurrentUserProvider);
    final heartLevelsAsync =
        ref.watch(client_home_providers.followedMerchantHeartLevelsForCurrentUserProvider);
    final followersCountAsync = ref.watch(
      client_home_providers.followersCountByMerchantIdsProvider(<String>[merchant.id]),
    );
    final viewedIdsAsync =
        ref.watch(client_home_providers.viewedMerchantIdsForCurrentUserProvider);
    final isFollowing = followedIdsAsync.valueOrNull?.contains(merchant.id) ?? false;
    final hasViewed = viewedIdsAsync.valueOrNull?.contains(merchant.id) ?? false;
    _markMerchantAsViewed(userId, merchant.id);
    final baseHeartLevel = isFollowing
        ? (heartLevelsAsync.valueOrNull?[merchant.id] ?? 1)
        : (hasViewed ? 1 : 0);
    final heartLevel =
        _optimisticHeartMerchantId == merchant.id && _optimisticHeartLevel != null
            ? _optimisticHeartLevel!
            : baseHeartLevel;
    final fetchedFollowersCount = followersCountAsync.valueOrNull?[merchant.id] ?? 0;
    final followersCount = isFollowing
        ? (fetchedFollowersCount < 1 ? 1 : fetchedFollowersCount)
        : fetchedFollowersCount;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: StorefrontColors.backgroundLight,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _followersLabelFr(followersCount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: StorefrontColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onNotifications,
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: StorefrontColors.primaryGold,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              StoreProfileBannerSection(
                  bannerImageUrl: merchant.bannerUrl ?? merchant.logoUrl,
                  profileImageUrl: merchant.logoUrl ?? merchant.bannerUrl,
                ),
                const SizedBox(height: 56),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: StorefrontColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                              child: Row(
                                children: List.generate(3, (index) {
                                  final target = index + 1;
                                  final isActive = heartLevel >= target;
                                  return Padding(
                                    padding: EdgeInsets.only(right: index == 2 ? 0 : 5),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _isFollowToggling
                                          ? null
                                          : () {
                                              final nextLevel =
                                                  heartLevel == target ? target - 1 : target;
                                              _setHeartLevel(
                                                context,
                                                userId: userId,
                                                merchantId: merchant.id,
                                                level: nextLevel,
                                              );
                                            },
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.favorite,
                                          color: isActive
                                              ? StorefrontColors.primaryGold
                                              : StorefrontColors.textSecondary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activity,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: StorefrontColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 4),
                      _buildSuivreButton(context, merchant.id),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NavigationTabs(
                  activeTab: _activeTab,
                  onTabChanged: (tab) => setState(() => _activeTab = tab),
                ),
                const SizedBox(height: 20),
                if (_activeTab == 'accueil') ...[
                  if (merchant.description != null && merchant.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        merchant.description!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.5,
                          color: StorefrontColors.textSecondary,
                        ),
                      ),
                    ),
                  if (merchant.description != null && merchant.description!.isNotEmpty)
                    const SizedBox(height: 20),
                  _buildSectionTitle('Téléphone'),
                  _buildInfoRow(Icons.phone_outlined, merchant.phone),
                  _buildSectionTitle('Adresse'),
                  _buildInfoRow(
                    Icons.place_outlined,
                    merchant.address ?? merchant.city,
                  ),
                  if (promotions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Promotions'),
                    const SizedBox(height: 4),
                    _buildPromotionsList(promotions),
                  ],
                ] else if (_activeTab == 'horaires') ...[
                  _buildSectionTitle('Horaires d\'ouverture'),
                  _buildHoursSection(hours),
                ] else if (_activeTab == 'actualite') ...[
                  NewsSection(
                    content: merchant.description,
                    imageUrls: merchant.newsImageUrls ?? const [],
                    showMedia: merchant.newsImageUrls?.isNotEmpty ?? false,
                    showUploadButton: false,
                    contentPlaceholder: 'Aucune actualité pour le moment.',
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _markMerchantAsViewed(String? userId, String merchantId) {
    if (userId == null || userId.isEmpty || merchantId.isEmpty) return;
    final key = '$userId::$merchantId';
    if (_lastViewedKey == key) return;
    _lastViewedKey = key;
    unawaited(
      ref
          .read(client_home_providers.viewedMerchantsLocalServiceProvider)
          .markViewed(userId, merchantId),
    );
    ref.invalidate(client_home_providers.viewedMerchantIdsForCurrentUserProvider);
  }

  String _followersLabelFr(int count) {
    if (count <= 1) return 'Ce commerce est suivi par $count personne';
    return 'Ce commerce est suivi par $count personnes';
  }

  Widget _buildSuivreButton(BuildContext context, String merchantId) {
    final userId = ref.watch(auth_providers.currentUserIdProvider);
    final followedAsync = ref.watch(client_home_providers.followedMerchantIdsForCurrentUserProvider);
    final isFollowing = followedAsync.valueOrNull?.contains(merchantId) ?? false;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isFollowToggling
                ? null
                : () async {
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connectez-vous pour suivre des commerces'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    setState(() => _isFollowToggling = true);
                    final repo = ref.read(followedMerchantsRepositoryProvider);
                    final result = isFollowing
                        ? await repo.remove(userId, merchantId)
                        : await repo.add(userId, merchantId);
                    if (!context.mounted) return;
                    setState(() => _isFollowToggling = false);

                    if (result.isLeft) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Échec de la sauvegarde du suivi'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    ref.invalidate(client_home_providers.followedMerchantIdsForCurrentUserProvider);
                    ref.invalidate(client_home_providers.followedMerchantHeartLevelsForCurrentUserProvider);
                    ref.invalidate(client_home_providers.clientHomeFeedProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFollowing
                              ? 'Vous ne suivez plus ce commerce'
                              : 'Commerce ajouté à votre carnet',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: StorefrontColors.primaryGold,
                      ),
                    );
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: StorefrontColors.primaryGold,
              side: const BorderSide(color: StorefrontColors.primaryGold),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isFollowToggling
                  ? '...'
                  : (isFollowing ? 'Ne plus suivre' : 'Suivre le commerce'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications en cours - bientôt disponible'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: StorefrontColors.primaryGold,
              side: const BorderSide(color: StorefrontColors.primaryGold),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Notifications en cours',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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
    final repo = ref.read(followedMerchantsRepositoryProvider);

    // Ensure merchant is followed before saving heart level.
    final addResult = await repo.add(userId, merchantId);
    // If user tapped again while this request was in-flight, ignore this response.
    if (token != _heartSaveToken) return;
    if (addResult.isLeft) {
      if (!context.mounted) return;
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

    final heartResult = await repo.setHeartLevel(userId, merchantId, level);
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
    ref.invalidate(client_home_providers.followedMerchantIdsForCurrentUserProvider);
    ref.invalidate(client_home_providers.followedMerchantHeartLevelsForCurrentUserProvider);
    ref.invalidate(client_home_providers.clientHomeFeedProvider);
    // Keep UI instant and quiet; no success snackbar on every tap.
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: StorefrontColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: StorefrontColors.primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: StorefrontColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursSection(BusinessHours? hours) {
    if (hours == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Horaires non renseignés',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: StorefrontColors.textSecondary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: hours.allDays.map((day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day.dayName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: StorefrontColors.textPrimary,
                  ),
                ),
                Text(
                  day.displayText,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: StorefrontColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromotionsList(List<Promotion> promotions) {
    if (promotions.isEmpty) {
      return _buildEmptyPromotions();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: promotions.map((promo) {
          final now = DateTime.now();
          final daysLeft = promo.dateTo.isAfter(now)
              ? promo.dateTo.difference(now).inDays
              : 0;
          final validText = daysLeft > 0
              ? 'Valide encore $daysLeft jours'
              : 'Expiré';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StorefrontColors.cardLight,
                border: Border.all(
                  color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: StorefrontColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_offer_outlined,
                      color: StorefrontColors.primaryGold,
                      size: 24,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: StorefrontColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: StorefrontColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          validText,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: StorefrontColors.primaryGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyPromotions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'Aucune promotion pour le moment',
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: StorefrontColors.textSecondary,
        ),
      ),
    );
  }
}
