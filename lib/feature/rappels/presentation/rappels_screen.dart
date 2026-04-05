import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../loyalty/application/client_loyalty_providers.dart'
    as client_loyalty_providers;
import '../../loyalty/domain/entities/loyalty_pending_client_row.dart';
import '../../loyalty/presentation/widgets/pending_loyalty_validations_section.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import 'widgets/notifications_auto_entry.dart';
import 'widgets/rappels_clients_section.dart';
import 'widgets/rappels_product_section.dart';
import 'widgets/rappels_toggles_section.dart';

/// Rappels screen – "Vos rappels" merchant page.
/// Toggles are loaded from and saved to Firestore.
class RappelsScreen extends ConsumerStatefulWidget {
  final void Function(String)? onNavigate;

  const RappelsScreen({super.key, this.onNavigate});

  @override
  ConsumerState<RappelsScreen> createState() => _RappelsScreenState();
}

class _RappelsScreenState extends ConsumerState<RappelsScreen> {
  final GlobalKey _pendingLoyaltySectionKey = GlobalKey();

  void _ensurePendingLoyaltySectionVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _pendingLoyaltySectionKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefront_providers.storefrontProvider);
    final merchantAsync = ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final Merchant? merchant = merchantAsync.valueOrNull;
    final LoyaltyProgramConfig loyaltyConfig = merchant?.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
          loyaltyEnabled: merchant?.loyaltyEnabled ?? false,
        );
    final bool isManualPassageValidation = merchant != null &&
        merchant.loyaltyEnabled &&
        loyaltyConfig.programEnabled &&
        loyaltyConfig.passageValidation == LoyaltyPassageValidation.manual;
    final String merchantId = merchant?.id ?? '';
    final AsyncValue<List<LoyaltyPendingClientRow>> pendingAsync =
        merchantId.isEmpty
            ? const AsyncValue<List<LoyaltyPendingClientRow>>.data(
                <LoyaltyPendingClientRow>[],
              )
            : ref.watch(
                client_loyalty_providers
                    .pendingLoyaltyClientsForMerchantProvider(merchantId),
              );
    final int totalPendingPassages = pendingAsync.maybeWhen(
      data: (List<LoyaltyPendingClientRow> rows) => rows.fold<int>(
        0,
        (int s, LoyaltyPendingClientRow r) => s + r.progress.pendingPassages,
      ),
      orElse: () => 0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: Column(
                  children: [
                    storefrontAsync.when(
                      data: (storefront) => RappelsClientsSection(
                        connectedClientsThisMonth:
                            storefront?.rappelsMonthlyConnectedClients ?? 0,
                        validatedPassagesThisMonth:
                            storefront?.rappelsMonthlyValidatedPassages ?? 0,
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap: _ensurePendingLoyaltySectionVisible,
                      ),
                      loading: () => RappelsClientsSection(
                        connectedClientsThisMonth: 0,
                        validatedPassagesThisMonth: 0,
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap: _ensurePendingLoyaltySectionVisible,
                      ),
                      error: (_, __) => RappelsClientsSection(
                        connectedClientsThisMonth: 0,
                        validatedPassagesThisMonth: 0,
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap: _ensurePendingLoyaltySectionVisible,
                      ),
                    ),
                    merchantAsync.when(
                      data: (Merchant? m) {
                        if (m == null) return const SizedBox.shrink();
                        return PendingLoyaltyValidationsSection(
                          key: _pendingLoyaltySectionKey,
                          merchant: m,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const RappelsProductSection(),
                    storefrontAsync.when(
                      data: (storefront) {
                        final autoClient =
                            storefront?.rappelsAutoClientValidation ?? true;
                        final autoPassage =
                            storefront?.rappelsAutoPassageValidation ?? true;
                        final merchantId = storefront?.id;
                        return RappelsTogglesSection(
                          autoClientValidation: autoClient,
                          autoPassageValidation: autoPassage,
                          onClientChanged: merchantId != null
                              ? (v) =>
                                  _saveRappels(ref, merchantId, v, autoPassage)
                              : (_) {},
                          onPassageChanged: merchantId != null
                              ? (v) =>
                                  _saveRappels(ref, merchantId, autoClient, v)
                              : (_) {},
                        );
                      },
                      loading: () => RappelsTogglesSection(
                        autoClientValidation: true,
                        autoPassageValidation: true,
                        onClientChanged: (_) {},
                        onPassageChanged: (_) {},
                      ),
                      error: (_, __) => RappelsTogglesSection(
                        autoClientValidation: true,
                        autoPassageValidation: true,
                        onClientChanged: (_) {},
                        onPassageChanged: (_) {},
                      ),
                    ),
                    NotificationsAutoEntry(
                      onTap: () =>
                          widget.onNavigate?.call('notifications-auto'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRappels(
    WidgetRef ref,
    String merchantId,
    bool autoClient,
    bool autoPassage,
  ) async {
    final updateRappels =
        ref.read(merchant_providers.updateRappelsSettingsProvider);
    final result = await updateRappels.call(
      merchantId: merchantId,
      rappelsAutoClientValidation: autoClient,
      rappelsAutoPassageValidation: autoPassage,
    );
    result.fold(
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors de l\'enregistrement',
                style: GoogleFonts.outfit(),
              ),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      },
      (_) {
        ref.invalidate(storefront_providers.storefrontProvider);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Text(
              'Vos rappels',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
