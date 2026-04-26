import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Product / feature section of the Rappels screen.
class RappelsProductSection extends StatelessWidget {
  const RappelsProductSection({super.key, this.onProgramNfc});

  /// Called when the merchant taps "Programmer NFC" — navigate to QR/NFC screen.
  final VoidCallback? onProgramNfc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureHeader(),
          const SizedBox(height: 16),
          _buildProductImage(),
          const SizedBox(height: 16),
          _featurePoint('Plus de QR code - un simple contact suffit.'),
          const SizedBox(height: 12),
          _featurePoint(
            'Un geste naturel pour vous, une expérience fluide pour vos clients',
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onProgramNfc,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: MerchantColors.gold.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.nfc_rounded,
                      color: MerchantColors.bgMain, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Programmer mon badge NFC',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.bgMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: MerchantColors.gold, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.bolt, color: MerchantColors.gold, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le petit objet qui change tout - facilitez votre quotidien et celui de vos clients',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Conçu en France, pour être utilisé des dizaines de fois par jour.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textGrey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.nfc_rounded,
            color: MerchantColors.gold,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            'Badge NFC Yuztoo',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Approchez — connecté en un instant',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check, color: MerchantColors.gold, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

