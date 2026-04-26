import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/vitrine_qr_config.dart';
import '../../../../core/shared/constants/merchant_colors.dart';

/// Gold-bordered QR code card: shows a real tappable QR code if [merchantId]
/// is provided, otherwise falls back to a static icon.
class ClientQrBox extends StatelessWidget {
  const ClientQrBox({
    super.key,
    this.merchantId = '',
    this.onTap,
  });

  final String merchantId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MerchantColors.gold, width: 1),
          ),
          child: Column(
            children: [
              if (merchantId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: VitrineQrConfig.uriStringForMerchant(merchantId),
                    version: QrVersions.auto,
                    size: 100,
                    gapless: true,
                  ),
                )
              else
                const Icon(
                  Icons.qr_code,
                  size: 100,
                  color: MerchantColors.gold,
                ),
              const SizedBox(height: 16),
              Text(
                'Faites scanner ce QR code\npour ajouter un client',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textLightGrey,
                  height: 1.6,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Appuyez pour agrandir',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: MerchantColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
