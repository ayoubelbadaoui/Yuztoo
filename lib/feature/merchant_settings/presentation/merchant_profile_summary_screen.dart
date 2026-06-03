import 'dart:io';

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
import '../../storefront/application/profile_view_providers.dart';
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
  bool _linkingApple = false;

  Future<void> _linkGoogle() async {
    if (_linkingGoogle) return;
    setState(() => _linkingGoogle = true);
    final link = ref.read(auth_providers.linkWithGoogleProvider);
    final Result<AuthUser> result = await link();
    if (!mounted) return;
    setState(() => _linkingGoogle = false);
    _handleLinkResult(result, providerLabel: 'Google');
  }

  Future<void> _linkApple() async {
    if (_linkingApple) return;
    setState(() => _linkingApple = true);
    final link = ref.read(auth_providers.linkWithAppleProvider);
    final Result<AuthUser> result = await link();
    if (!mounted) return;
    setState(() => _linkingApple = false);
    _handleLinkResult(result, providerLabel: 'Apple');
  }

  // Single handler so the Google/Apple flows stay symmetric — same
  // success snackbar, same swallow-on-cancel, same provider invalidation.
  void _handleLinkResult(Result<AuthUser> result,
      {required String providerLabel}) {
    result.fold(
      (failure) {
        if (failure.runtimeType.toString().contains('UserCancelled')) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) {
        ref.invalidate(auth_providers.linkedProvidersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compte $providerLabel associé ✓'),
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

    // Live 7-day sliding window count from
    // [profileViewWeeklyStatsProvider] — replaces the now-deprecated
    // `storefront.weeklyViews` stub which always returned 0.
    final weeklyViews = merchantId.isEmpty
        ? 0
        : ref
                .watch(profileViewWeeklyStatsProvider(merchantId))
                .valueOrNull
                ?.weeklyViews ??
            0;

    return _buildScaffold(
      context,
      merchant: merchant,
      storefront: storefront,
      clientCount: clients.length,
      partnerCount: partners.length,
      cityCount: cities.length,
      weeklyViews: weeklyViews,
      completionPct: storefront?.profileCompletionPercentage ?? 0,
      linkedProviders: linkedProviders,
    );
  }
}
