import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../loyalty/presentation/widgets/reward_redemption_section.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../../storefront/domain/entities/storefront.dart';
import '../application/providers.dart' as rappels_providers;
import 'widgets/alertes_section.dart';
import 'widgets/pending_clients_section.dart';
import 'widgets/notifications_auto_entry.dart';
import 'widgets/quick_send_section.dart';
import 'widgets/rappels_clients_section.dart';
// Kept while RappelsProductSection is hidden (see rappels_screen.part.dart)
// so re-enabling the NFC plaque marketing block is a single-line revert.
// ignore: unused_import
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
  final GlobalKey _togglesSectionKey = GlobalKey();

  // One-time welcome popup per app session.
  static bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    if (!_hasShownWelcome) {
      _hasShownWelcome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWelcomePopup();
      });
    }
  }

  void _showWelcomePopup() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderStronger),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  border: Border.all(color: MerchantColors.gold, width: 2),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: MerchantColors.gold, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Comment ça marche ?',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Retrouvez ici les clients ayant scanné votre QR code et '
                'gérez vos notifications automatiques. '
                'Les demandes de passage fidélité se valident dans '
                '« Vos clients » (section Validation des passages).',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textLightGrey,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Compris !',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.darkOverlay,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToToggles() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _togglesSectionKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        );
      }
    });
  }

  Future<void> _onQuickSend(
    String text,
    String audience,
    List<String> segments,
  ) async {
    final merchant = ref.read(merchant_providers.currentMerchantForOwnerProvider).valueOrNull;
    if (merchant == null) return;
    final useCase = ref.read(rappels_providers.sendMerchantNotificationProvider);
    final result = await useCase.call(
      merchantId: merchant.id,
      merchantName: merchant.name,
      text: text,
      audience: audience,
      segments: segments,
      callerUid: merchant.ownerUid,
    );
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red[400],
        ),
      ),
      (sent) {
        ref.invalidate(rappels_providers.sentNotificationsProvider(merchant.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification envoyée à $sent client${sent > 1 ? 's' : ''}',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefront_providers.storefrontProvider);
    final merchantAsync = ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final Merchant? merchant = merchantAsync.valueOrNull;

    return _buildRappelsScaffold(
      context,
      storefrontAsync: storefrontAsync,
      merchantAsync: merchantAsync,
      merchant: merchant,
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
