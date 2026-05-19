import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../storefront/presentation/widgets/storefront_colors.dart';

/// Prompts the merchant for the client's purchase amount in € during a
/// passage validation. Returns null on cancel, the parsed number on submit
/// (',' and '.' both accepted as decimal separator).
///
/// Single source of truth — used by both the BLE detection sheet and the
/// active-validation sheet so the inputs share the same gold-accent style
/// and minimum-hint UX.
Future<double?> showMerchantSpendAmountDialog(
  BuildContext context, {
  double? minimumPerVisitEuros,
}) {
  final ctrl = TextEditingController();
  final hint = (minimumPerVisitEuros != null && minimumPerVisitEuros > 0)
      ? 'Minimum ${_formatMin(minimumPerVisitEuros)} €'
      : null;
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: MerchantColors.navyCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Montant de l\'achat',
        style: GoogleFonts.outfit(
          color: MerchantColors.textWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
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
                fontWeight: FontWeight.w600,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: MerchantColors.gold),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: StorefrontColors.primaryGold,
                  width: 2,
                ),
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 10),
            Text(
              hint,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: const Text(
            'Annuler',
            style: TextStyle(color: MerchantColors.textGrey),
          ),
        ),
        TextButton(
          onPressed: () {
            final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
            Navigator.of(ctx).pop(v);
          },
          child: const Text(
            'Valider',
            style: TextStyle(
              color: StorefrontColors.primaryGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatMin(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}
