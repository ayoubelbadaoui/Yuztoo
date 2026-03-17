import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../../merchant/application/providers.dart' as merchant_providers;
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
  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefront_providers.storefrontProvider);

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
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const RappelsClientsSection(),
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
