import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/infrastructure/ble_proximity_notifier.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
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
    final needsAmount =
        merchant.loyaltyProgram?.effectiveAskClientPurchaseAmount ?? false;

    double? amount;
    if (needsAmount) {
      amount = await _showAmountDialog();
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

  Future<double?> _showAmountDialog() {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.navyCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Montant de l\'achat',
          style: GoogleFonts.outfit(
              color: MerchantColors.textWhite,
              fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: MerchantColors.textWhite),
          decoration: const InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: MerchantColors.textGrey),
            suffixText: '€',
            suffixStyle: TextStyle(
                color: StorefrontColors.primaryGold,
                fontWeight: FontWeight.w600),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: MerchantColors.gold)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: StorefrontColors.primaryGold, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuler',
                style: TextStyle(color: MerchantColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              final v =
                  double.tryParse(ctrl.text.replaceAll(',', '.'));
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Valider',
                style: TextStyle(
                    color: StorefrontColors.primaryGold,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);

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

          const SizedBox(height: 12),

          // Ignore
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
      ),
    );
  }
}
