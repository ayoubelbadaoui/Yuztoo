import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/yuztoo_official_page.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';

/// Contact details of the YuzToo team, read from the YuzToo page.
/// Null when the current project has no YuzToo page.
final yuztooContactProvider =
    FutureProvider.autoDispose<Merchant?>((ref) async {
  final id = YuztooOfficialPage.merchantId();
  if (id == null) return null;
  final result =
      await ref.watch(merchantRepositoryProvider).getMerchantById(id);
  return result.fold((failure) => throw failure, (m) => m);
});
