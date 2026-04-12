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
export '../../followed_merchants/application/providers.dart'
    show toggleMerchantFollowProvider, ensureFollowedAndSetHeartLevelProvider;
export '../../loyalty/application/client_loyalty_providers.dart'
    show
        clientLoyaltyProgressForMerchantProvider,
        recordLoyaltyPassageProvider;

/// When the user taps a business (Accueil or Découvrir), set this to the merchant id
/// before navigating to store profile.
final selectedStoreMerchantIdProvider = StateProvider<String?>((ref) => null);

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
    (List<Promotion> list) => list,
  );

  return (merchant: merchant, promotions: promotions);
});
