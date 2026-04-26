import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../client_list/application/providers.dart' as crm_providers;
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant_partners/application/providers.dart' as partners_providers;
import '../../storefront/application/providers.dart' as storefront_providers;
import '../../storefront/domain/entities/storefront.dart';

part 'merchant_profile_summary_screen.part.dart';

/// "Mon profil pro" summary screen — KPIs, completion bar, Google sync toggle.
class MerchantProfileSummaryScreen extends ConsumerStatefulWidget {
  const MerchantProfileSummaryScreen({
    super.key,
    this.onBack,
    this.onNavigate,
  });

  final VoidCallback? onBack;
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<MerchantProfileSummaryScreen> createState() =>
      _MerchantProfileSummaryScreenState();
}

class _MerchantProfileSummaryScreenState
    extends ConsumerState<MerchantProfileSummaryScreen> {
  bool _googleSyncEnabled = false;

  void _onGoogleSyncToggle(bool value) {
    if (!value) {
      setState(() => _googleSyncEnabled = false);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComingSoonSheet(
        onClose: () {
          Navigator.pop(context);
          setState(() => _googleSyncEnabled = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref
        .watch(merchant_providers.currentMerchantForOwnerProvider)
        .valueOrNull;
    final merchantId = merchant?.id ?? '';

    final storefront =
        ref.watch(storefront_providers.storefrontProvider).valueOrNull;

    final clients = merchantId.isEmpty
        ? const <dynamic>[]
        : (ref
                .watch(crm_providers.merchantClientsProvider(merchantId))
                .valueOrNull ??
            const []);

    final partners = merchantId.isEmpty
        ? const <dynamic>[]
        : (ref
                .watch(partners_providers.merchantPartnersProvider(merchantId))
                .valueOrNull ??
            const []);

    return _buildScaffold(
      context,
      merchant: merchant,
      storefront: storefront,
      clientCount: clients.length,
      partnerCount: partners.length,
      completionPct: storefront?.profileCompletionPercentage ?? 0,
    );
  }
}
