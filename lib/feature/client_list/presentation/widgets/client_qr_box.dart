import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Gold-bordered QR code card: icon + gold QR + scan instruction.
class ClientQrBox extends StatelessWidget {
  const ClientQrBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MerchantColors.gold, width: 1),
        ),
        child: Column(
          children: [
            // ── gold QR code ──
            const Icon(
              Icons.qr_code,
              size: 100,
              color: MerchantColors.gold,
            ),
            const SizedBox(height: 20),

            // ── instruction text ──
            Text(
              'Faites scanner ce QR code\npour ajouter un client',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
