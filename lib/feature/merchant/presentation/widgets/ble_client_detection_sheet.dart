import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/infrastructure/ble_proximity_notifier.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../loyalty/presentation/widgets/merchant_spend_amount_dialog.dart';
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

  String get _initials {
    final parts = _clientName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return _clientName.isNotEmpty ? _clientName[0].toUpperCase() : '?';
  }

  void _ignore() {
    Navigator.of(context).pop();
    widget.onDismiss();
  }

  Future<void> _confirm(Merchant merchant) async {
    final config = merchant.loyaltyProgram;
    final needsAmount = config?.effectiveAskClientPurchaseAmount ?? false;
    final double? minimumPerVisitEuros = (config?.minimumPerVisitEnabled ?? false)
        ? config?.minimumPerVisitEuros
        : null;

    double? amount;
    if (needsAmount) {
      amount = await showMerchantSpendAmountDialog(
        context,
        minimumPerVisitEuros: minimumPerVisitEuros,
      );
      if (!mounted) return;
      if (amount == null) return; // cancelled — keep sheet open
    }

    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    final useCase =
        ref.read(merchant_providers.merchantRecordClientPassageProvider);
    final result = await useCase.call(
      clientUid: widget.detection.clientId,
      merchant: merchant,
      purchaseAmountEuros: amount,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isConfirming = false;
          _errorMessage = failure.message;
        });
      },
      (_) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        widget.onDismiss();
      },
    );
  }

  bool _merchantLoyaltyLive(Merchant? m) {
    if (m == null) return false;
    return m.loyaltyEnabled &&
        (m.loyaltyProgram?.programEnabled ?? m.loyaltyEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final merchant = merchantAsync.valueOrNull;
    final loyaltyOff =
        merchant != null && !_merchantLoyaltyLive(merchant);

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

          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.gold.withValues(alpha: 0.15),
              border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.4),
                  width: 2),
            ),
            child: Center(
              child: Text(
                _initials,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.gold,
                ),
              ),
            ),
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
