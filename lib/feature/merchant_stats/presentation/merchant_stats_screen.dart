import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../client_list/application/providers.dart' as crm_providers;
import '../../client_list/domain/entities/merchant_client_row.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../rappels/application/providers.dart' as rappels_providers;
import '../../rappels/domain/entities/pending_client_row.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../../storefront/domain/entities/storefront.dart';

part 'merchant_stats_screen.part.dart';

class MerchantStatsScreen extends ConsumerStatefulWidget {
  const MerchantStatsScreen({super.key, required this.onBack});

  static String get path => '/merchant-stats';

  final VoidCallback onBack;

  @override
  ConsumerState<MerchantStatsScreen> createState() =>
      _MerchantStatsScreenState();
}

class _MerchantStatsScreenState extends ConsumerState<MerchantStatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final merchantId = merchantAsync.valueOrNull?.id ?? '';

    final clientsAsync =
        ref.watch(crm_providers.merchantClientsProvider(merchantId));
    final storefrontAsync =
        ref.watch(storefront_providers.storefrontProvider);
    final pendingAsync = merchantId.isEmpty
        ? const AsyncValue<List<PendingClientRow>>.data([])
        : ref.watch(
            rappels_providers.pendingClientsForMerchantProvider(merchantId),
          );

    return _buildStatsBody(
      context,
      merchantId: merchantId,
      clientsAsync: clientsAsync,
      storefrontAsync: storefrontAsync,
      pendingAsync: pendingAsync,
    );
  }
}
