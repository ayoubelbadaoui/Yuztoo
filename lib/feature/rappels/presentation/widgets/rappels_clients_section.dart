import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import 'rappels_section_header.dart';

/// "Nouveaux clients et Passage" section of the Rappels screen.
class RappelsClientsSection extends StatelessWidget {
  const RappelsClientsSection({
    super.key,
    required this.connectedClientsThisMonth,
    required this.validatedPassagesThisMonth,
    this.pendingLoyaltyPassagesToConfirm = 0,
    this.isManualPassageValidation = false,
    this.onConfirmPendingPassagesTap,
  });

  /// Clients connectés ce mois (Firestore `rappels_monthly_connected_clients`).
  final int connectedClientsThisMonth;

  /// Passages validés ce mois (Firestore `rappels_monthly_validated_passages`).
  final int validatedPassagesThisMonth;

  /// Somme des `pending_passages` (fidélité à validation manuelle).
  final int pendingLoyaltyPassagesToConfirm;

  /// Vrai si le programme exige une validation marchand des passages.
  final bool isManualPassageValidation;

  /// Défile vers la liste « Passages à valider » (fidélité).
  final VoidCallback? onConfirmPendingPassagesTap;

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
    final previewCount = connectedClientsThisMonth > 4
        ? 4
        : connectedClientsThisMonth;

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
        ...List.generate(previewCount, (_) => _avatar()),
        Tooltip(
          message: !isManualPassageValidation
              ? 'Les passages fidélité sont validés automatiquement.'
              : (pendingLoyaltyPassagesToConfirm <= 0
                  ? 'Aucun passage en attente pour le moment.'
                  : 'Voir les passages à valider'),
          child: ElevatedButton(
            onPressed: isManualPassageValidation &&
                    pendingLoyaltyPassagesToConfirm > 0 &&
                    onConfirmPendingPassagesTap != null
                ? onConfirmPendingPassagesTap
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: MerchantColors.gold,
              foregroundColor: MerchantColors.darkOverlay,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              disabledBackgroundColor: MerchantColors.navyCard,
              disabledForegroundColor: MerchantColors.textLightGrey,
              textStyle: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(
              !isManualPassageValidation
                  ? 'Auto'
                  : (pendingLoyaltyPassagesToConfirm > 0
                      ? 'Confirmer ($pendingLoyaltyPassagesToConfirm)'
                      : 'Confirmer'),
            ),
          ),
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
          _statItem('$connectedClientsThisMonth clients connectés'),
          const SizedBox(height: 4),
          _statItem('$validatedPassagesThisMonth passages validés'),
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
        isManualPassageValidation
            ? 'Les demandes de passages fidélité (validation manuelle) apparaissent dans la section « Passages à valider » sous ce bloc, ou via le bouton Confirmer.'
            : 'Retrouvez ici les clients ayant scannés votre QR code pour valider un passage',
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: MerchantColors.textLightGrey,
          height: 1.6,
        ),
      ),
    );
  }
}

