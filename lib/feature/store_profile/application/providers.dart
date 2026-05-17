import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/core/result.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../promotions/domain/entities/promotion.dart';
import '../../promotions/infrastructure/promotion_repository_provider.dart';

export '../../auth/core/application/providers.dart' show currentUserIdProvider;
export '../../client_home/application/providers.dart'
    show
        followedMerchantIdsForCurrentUserProvider,
        followedMerchantHeartLevelsForCurrentUserProvider,
        followersCountByMerchantIdsProvider,
        viewedMerchantIdsForCurrentUserProvider,
        viewedMerchantsLocalServiceProvider,
        clientHomeFeedProvider;
export '../../discovery/application/providers.dart'
    show
        discoveryFollowedMerchantsProvider,
        discoveryMerchantsProvider,
        discoveryRecommendedMerchantsProvider;
export '../../followed_merchants/application/providers.dart'
    show
        toggleMerchantFollowProvider,
        ensureFollowedAndSetHeartLevelProvider,
        merchantMuteStateProvider,
        setMuteStateProvider;
export '../../loyalty/application/client_loyalty_providers.dart'
    show
        clientLoyaltyProgressForMerchantProvider,
        recordLoyaltyPassageProvider,
        ClientLoyaltyEntry;
export '../../profile/application/user_safety_providers.dart'
    show blockedMerchantIdsProvider, userSafetyRepositoryProvider;
export '../../profile/domain/repositories/user_safety_repository.dart'
    show ReportReason, ReportTargetType, UserSafetyRepository;

/// When the user taps a business (Accueil or Découvrir), set this to the merchant id
/// before navigating to store profile.
final selectedStoreMerchantIdProvider = StateProvider<String?>((ref) => null);

/// One-shot promotion deep-link target. When the user taps a notification or
/// push that references a specific promotion, the navigation handler sets the
/// promotion id alongside [selectedStoreMerchantIdProvider]; the storefront
/// screen consumes (and clears) this value on first build to auto-open the
/// promotion detail sheet. Without this the user landed on the storefront
/// and had to hunt for the promotion that triggered their notification.
final pendingStorePromotionIdProvider = StateProvider<String?>((ref) => null);

/// How the user arrived on the vitrine from a QR/NFC scan (one-shot).
///
/// [VitrineScanIntent.fromQrOrNfc] drives the post-scan funnel:
/// guest → connect-to-store sheet; logged-in non-follower → follow + welcome
/// then passage; already following → passage sheet.
enum VitrineScanIntent {
  none,
  fromQrOrNfc,
}

/// Set by QR/NFC before navigating to [StoreProfileScreen]. Reset to
/// [VitrineScanIntent.none] once the storefront has consumed the intent.
final pendingVitrineScanIntentProvider =
    StateProvider<VitrineScanIntent>((ref) => VitrineScanIntent.none);

/// Merchant + promotions loaded in parallel for one spinner and aligned paint.
typedef StoreProfilePageData = ({Merchant? merchant, List<Promotion> promotions});

final storeProfilePageDataProvider =
    FutureProvider<StoreProfilePageData>((ref) async {
  final merchantId = ref.watch(selectedStoreMerchantIdProvider);
  if (merchantId == null || merchantId.isEmpty) {
    return (merchant: null, promotions: <Promotion>[]);
  }
  final merchantRepo = ref.watch(merchantRepositoryProvider);
  final promoRepo = ref.watch(promotionRepositoryProvider);

  final results = await Future.wait([
    merchantRepo.getMerchantById(merchantId),
    promoRepo.listByMerchantId(merchantId),
  ]);

  final merchant = (results[0] as Result<Merchant?>).fold(
    (_) => null,
    (Merchant? m) => m,
  );
  final promotions = (results[1] as Result<List<Promotion>>).fold(
    (_) => <Promotion>[],
    // Only show promotions that are online and not yet expired.
    (List<Promotion> list) => list
        .where((p) => p.isOnline && p.dateTo.isAfter(DateTime.now()))
        .toList(),
  );

  return (merchant: merchant, promotions: promotions);
});
