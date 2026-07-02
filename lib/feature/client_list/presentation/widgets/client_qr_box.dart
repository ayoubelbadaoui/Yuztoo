import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/vitrine_qr_config.dart';
import '../../../../core/shared/constants/merchant_colors.dart';

/// Compact "connect a client" card shown at the top of the Vos clients list
/// (and as the empty-state CTA). Presents the merchant's QR thumbnail next to
/// a short explanation and the two available methods — QR code & badge NFC —
/// then routes to the full "Mon QR Code" screen (QR + share + NFC programming)
/// when tapped.
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MerchantColors.navyCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderStronger),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _qrThumbnail(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connecter un client',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Faites scanner votre QR ou programmez '
                            'un badge NFC pour ajouter un client.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: MerchantColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const _MethodChip(
                      icon: Icons.qr_code_rounded,
                      label: 'QR code',
                    ),
                    const SizedBox(width: 8),
                    const _MethodChip(
                      icon: Icons.nfc_rounded,
                      label: 'Badge NFC',
                    ),
                    const Spacer(),
                    if (onTap != null) _openPill(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qrThumbnail() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(6),
      child: merchantId.isNotEmpty
          ? QrImageView(
              data: VitrineQrConfig.uriStringForMerchant(merchantId),
              version: QrVersions.auto,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: MerchantColors.bgHeader,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: MerchantColors.bgHeader,
              ),
            )
          : const Icon(
              Icons.qr_code_2_rounded,
              size: 44,
              color: MerchantColors.bgHeader,
            ),
    );
  }

  Widget _openPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: MerchantColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ouvrir',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MerchantColors.bgHeader,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 11,
            color: MerchantColors.bgHeader,
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MerchantColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: MerchantColors.gold),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MerchantColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
