import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/domain/core/result.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/domain/entities/auth_user.dart';
import '../../auth/core/application/state/auth_state.dart';
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
  bool _linkingGoogle = false;

  Future<void> _linkGoogle() async {
    if (_linkingGoogle) return;
    setState(() => _linkingGoogle = true);
    final link = ref.read(auth_providers.linkWithGoogleProvider);
    final Result<AuthUser> result = await link();
    if (!mounted) return;
    setState(() => _linkingGoogle = false);
    result.fold(
      (failure) {
        // UserCancelledFailure: silently ignore
        if (failure.runtimeType.toString().contains('UserCancelled')) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) {
        // Refresh the provider to reflect new linked providers.
        ref.invalidate(auth_providers.linkedProvidersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte Google associé ✓'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
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

    final authState = ref.watch(auth_providers.authStateProvider);
    final uid = authState is Authenticated ? authState.user.id : '';
    final cities = uid.isEmpty
        ? const <String>[]
        : (ref.watch(auth_providers.connectedCitiesProvider(uid)).valueOrNull ??
            const []);

    final linkedProviders = ref.watch(auth_providers.linkedProvidersProvider);

    return _buildScaffold(
      context,
      merchant: merchant,
      storefront: storefront,
      clientCount: clients.length,
      partnerCount: partners.length,
      cityCount: cities.length,
      weeklyViews: storefront?.weeklyViews ?? 0,
      completionPct: storefront?.profileCompletionPercentage ?? 0,
      linkedProviders: linkedProviders,
    );
  }
}
