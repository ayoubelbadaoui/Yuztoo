import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Product / feature section of the Rappels screen.
class RappelsProductSection extends StatelessWidget {
  const RappelsProductSection({super.key});

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
            'Disponible prochainement',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
              fontStyle: FontStyle.italic,
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

