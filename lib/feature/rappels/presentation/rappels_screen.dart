import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../loyalty/application/client_loyalty_providers.dart'
    as client_loyalty_providers;
import '../../loyalty/application/widgets.dart';
import '../../loyalty/domain/entities/loyalty_pending_client_row.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../../storefront/domain/entities/storefront.dart';
import 'widgets/notifications_auto_entry.dart';
import 'widgets/rappels_clients_section.dart';
import 'widgets/rappels_product_section.dart';
import 'widgets/rappels_toggles_section.dart';

part 'rappels_screen.part.dart';

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

    return _buildRappelsScaffold(
      context,
      storefrontAsync: storefrontAsync,
      merchantAsync: merchantAsync,
      merchant: merchant,
      isManualPassageValidation: isManualPassageValidation,
      totalPendingPassages: totalPendingPassages,
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
}
