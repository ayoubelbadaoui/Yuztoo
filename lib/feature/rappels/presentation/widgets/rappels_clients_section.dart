import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import 'rappels_section_header.dart';

/// "Nouveaux clients et Passage" section of the Rappels screen.
class RappelsClientsSection extends StatelessWidget {
  const RappelsClientsSection({super.key});

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
          const RappelsSectionHeader(
            icon: Icons.people_outline,
            title: 'Nouveaux clients et Passage',
            subtitle: 'fidélité à confirmer',
          ),
          const SizedBox(height: 16),
          _buildClientsRow(),
          const SizedBox(height: 16),
          _buildStatsBox(),
          const SizedBox(height: 16),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildClientsRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Trophy icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MerchantColors.navyCard,
            border: Border.all(color: MerchantColors.gold, width: 3),
          ),
          child: const Center(
            child: Icon(Icons.emoji_events, color: MerchantColors.gold, size: 26),
          ),
        ),
        // 4 client avatars
        ...List.generate(4, (_) => _avatar()),
        // Confirm button
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: MerchantColors.gold,
            foregroundColor: MerchantColors.darkOverlay,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            textStyle: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  Widget _avatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MerchantColors.navyCard,
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: const Center(
        child: Icon(Icons.person_outline, color: MerchantColors.gold, size: 20),
      ),
    );
  }

  Widget _buildStatsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ce mois-ci:',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _statItem('12 clients connectés'),
          const SizedBox(height: 4),
          _statItem('8 passages validés'),
        ],
      ),
    );
  }

  Widget _statItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check, color: MerchantColors.gold, size: 14),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.outfit(fontSize: 12, color: MerchantColors.gold)),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderStronger),
          width: 1,
        ),
      ),
      child: Text(
        'Retrouvez ici les clients ayant scannés votre QR code pour valider un passage',
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: MerchantColors.textLightGrey,
          height: 1.6,
        ),
      ),
    );
  }
}

