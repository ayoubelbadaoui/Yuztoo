import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/infrastructure/ble_proximity_notifier.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/shared/widgets/proximity_list_avatar.dart';
import '../../../loyalty/domain/entities/active_validation_request.dart';
import '../../../loyalty/domain/loyalty_passage_program_policy.dart';
import '../../../loyalty/infrastructure/active_validation_repository_provider.dart';
import '../../../loyalty/presentation/merchant_passage_validation_flow.dart';
import '../../../storefront/presentation/widgets/storefront_colors.dart';
import '../../application/providers.dart' as merchant_providers;
import '../../domain/entities/merchant.dart';

/// Bottom sheet shown automatically on the merchant's phone when a client is
/// detected via BLE proximity.  No Bluetooth iconography — the user experience
/// is "client arrived", not "Bluetooth connected".
///
/// Calls [onDismiss] (confirm or ignore) so the shell can reset the BLE scan.
class BleClientDetectionSheet extends ConsumerStatefulWidget {
  const BleClientDetectionSheet({
    super.key,
    required this.detection,
    required this.onDismiss,
  });

  final BleClientDetection detection;

  /// Called after the sheet completes (confirm or ignore).
  /// The shell uses this to call [BleProximityNotifier.resetAfterDetection].
  final VoidCallback onDismiss;

  @override
  ConsumerState<BleClientDetectionSheet> createState() =>
      _BleClientDetectionSheetState();
}

class _BleClientDetectionSheetState
    extends ConsumerState<BleClientDetectionSheet> {
  bool _isConfirming = false;
  String? _errorMessage;

  String get _clientName =>
      widget.detection.displayName?.isNotEmpty == true
          ? widget.detection.displayName!
          : 'Client';

  void _ignore() {
    Navigator.of(context).pop();
    widget.onDismiss();
  }

  Future<void> _confirm(Merchant merchant) async {
    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    ActiveValidationRequest? session;
    try {
      session = await ref
          .read(activeValidationRepositoryProvider)
          .watchClientSession(
            merchantId: merchant.id,
            clientUid: widget.detection.clientId,
          )
          .first;
    } catch (_) {
      session = null;
    }

    if (!mounted) return;

    if (session == null) {
      setState(() {
        _isConfirming = false;
        _errorMessage =
            'Le client doit d\'abord confirmer la connexion sur son téléphone.';
      });
      return;
    }

    final opened = await openMerchantPassageValidation(
      ref: ref,
      context: context,
      merchant: merchant,
      session: session,
      connectMerchantBle: true,
    );

    if (!mounted) return;

    setState(() => _isConfirming = false);

    if (opened) {
      Navigator.of(context).pop();
      widget.onDismiss();
    }
  }

  bool _merchantBlePassageAllowed(Merchant? m) {
    if (m == null) return false;
    return isBlePassageAllowedForMerchant(m);
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final merchant = merchantAsync.valueOrNull;
    final loyaltyOff =
        merchant != null && !_merchantBlePassageAllowed(merchant);

    return Container(
      decoration: const BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: MerchantColors.textGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          ProximityListAvatar(
            imageUrl: widget.detection.photoUrl,
            label: _clientName,
            size: 72,
            fallbackIcon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 16),

          // Label
          Text(
            'Client à proximité',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textGrey,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 6),

          // Name
          Text(
            _clientName,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: MerchantColors.textWhite,
            ),
          ),

          const SizedBox(height: 28),

          // Error
          if (_errorMessage != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: Colors.red.shade300),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (loyaltyOff) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'La fidélité est désactivée pour votre commerce. Réactivez '
                'E-Fidélité pour enregistrer des passages fidélité depuis cette '
                'fenêtre.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.45,
                  color: MerchantColors.textLightGrey,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isConfirming ? null : _ignore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MerchantColors.gold,
                  side: const BorderSide(color: MerchantColors.gold),
                ),
                child: Text(
                  'Fermer',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            // Confirm button
            merchantAsync.when(
            data: (merchant) => SizedBox(
              width: double.infinity,
              height: 52,
              child: GestureDetector(
                onTap: (_isConfirming || merchant == null)
                    ? null
                    : () => _confirm(merchant),
                child: Container(
                  decoration: BoxDecoration(
                    color: merchant != null
                        ? MerchantColors.gold
                        : MerchantColors.gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isConfirming
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: StorefrontColors.navyDark,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Confirmer le passage',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: StorefrontColors.navyDark,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            loading: () => SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: MerchantColors.gold, strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (_, __) => SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Commerce indisponible',
                    style: GoogleFonts.outfit(
                        color: MerchantColors.textGrey, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),

            if (!loyaltyOff) const SizedBox(height: 12),

            if (!loyaltyOff)
              GestureDetector(
                onTap: _isConfirming ? null : _ignore,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Ignorer',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
