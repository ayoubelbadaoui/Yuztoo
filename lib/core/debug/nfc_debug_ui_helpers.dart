import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../infrastructure/nfc_service.dart';
import '../shared/constants/merchant_colors.dart';
import '../shared/widgets/snackbar.dart';

/// Applies the same snackbars / navigation as [NfcService.readVitrineMerchantId]
/// consumers (QR scanner, debug emulator).
void applyNfcReadResult(
  BuildContext context,
  NfcResult result, {
  required void Function(String merchantId) onValidMerchantId,
}) {
  switch (result) {
    case NfcSuccess(:final merchantId):
      if (merchantId != null && merchantId.isNotEmpty) {
        onValidMerchantId(merchantId);
      } else {
        _nfcSnack(
          context,
          'Aucune vitrine Yuztoo détectée par NFC.',
        );
      }
    case NfcUnavailable():
      _nfcSnack(context, 'NFC non disponible.');
    case NfcError(:final message):
      if (message != 'Lecture annulée.') {
        _nfcSnack(context, message);
      }
  }
}

/// Applies merchant write feedback (merchant QR screen + debug emulator).
void applyNfcWriteResult(BuildContext context, NfcResult result) {
  switch (result) {
    case NfcSuccess():
      _nfcSnack(
        context,
        'Badge NFC programmé avec succès !',
        success: true,
      );
    case NfcUnavailable():
      _nfcSnack(context, 'NFC non disponible sur cet appareil.');
    case NfcError(:final message):
      _nfcSnack(context, message, error: true);
  }
}

void _nfcSnack(
  BuildContext context,
  String message, {
  bool success = false,
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: success
            ? merchantSnackBarTextOnWarmAccent()
                .copyWith(fontWeight: FontWeight.w600)
            : merchantSnackBarTextOnDark(),
      ),
      backgroundColor: success
          ? const Color(0xFF1B7A4B)
          : error
              ? Colors.red.shade700
              : MerchantColors.navyCard,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: success ? 3 : 4),
    ),
  );
}

Widget nfcDebugBanner({required String label}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.orange.shade700),
    ),
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.orange.shade200,
        letterSpacing: 0.6,
      ),
    ),
  );
}
