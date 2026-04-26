import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/core/result.dart';
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

/// Returns the mute state (true = muted) for the current user + given merchant.
final merchantMuteStateProvider =
    FutureProvider.family<bool, ({String userId, String merchantId})>(
        (ref, args) async {
  if (args.userId.isEmpty || args.merchantId.isEmpty) return false;
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  final result = await repo.getMuteState(args.userId, args.merchantId);
  return result.fold((_) => false, (v) => v);
});

/// Sets the mute state.  Use `ref.read` — returns the result.
final setMuteStateProvider =
    Provider<Future<Result<Unit>> Function(String, String, {required bool muted})>(
  (ref) {
    final repo = ref.watch(followedMerchantsRepositoryProvider);
    return (userId, merchantId, {required bool muted}) =>
        repo.setMuteState(userId, merchantId, muted: muted);
  },
);
