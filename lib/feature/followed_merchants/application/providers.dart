import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/followed_merchants_repository_provider.dart';
import 'use_cases/ensure_followed_and_set_heart_level.dart';
import 'use_cases/toggle_merchant_follow.dart';

final toggleMerchantFollowProvider = Provider<ToggleMerchantFollow>((ref) {
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  return ToggleMerchantFollow(repo);
});

final ensureFollowedAndSetHeartLevelProvider =
    Provider<EnsureFollowedAndSetHeartLevel>((ref) {
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  return EnsureFollowedAndSetHeartLevel(repo);
});
