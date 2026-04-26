part of 'rappels_clients_section.dart';

extension _RappelsClientsSectionUi on RappelsClientsSection {
  Widget _buildRappelsClientsBody(BuildContext context) {
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
            icon: Icons.people_outline_rounded,
            title: 'Nouveaux clients et Passage',
            subtitle: 'fidélité à confirmer',
          ),
          const SizedBox(height: 16),
          _buildClientsRow(),
          const SizedBox(height: 16),
          _buildStatsBox(),
        ],
      ),
    );
  }

  Widget _buildClientsRow() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MerchantColors.gold.withValues(alpha: 0.15),
            border: Border.all(color: MerchantColors.gold, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.people_outline_rounded,
                color: MerchantColors.gold, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                connectedClientsThisMonth == 0
                    ? 'Aucun nouveau client ce mois-ci'
                    : '$connectedClientsThisMonth nouveau${connectedClientsThisMonth > 1 ? 'x' : ''} client${connectedClientsThisMonth > 1 ? 's' : ''} ce mois',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (pendingLoyaltyPassagesToConfirm > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '$pendingLoyaltyPassagesToConfirm passage${pendingLoyaltyPassagesToConfirm > 1 ? 's' : ''} en attente',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: MerchantColors.gold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: !isManualPassageValidation
              ? 'Appuyez pour modifier le mode de validation'
              : (pendingLoyaltyPassagesToConfirm <= 0
                  ? 'Aucun passage en attente pour le moment.'
                  : 'Voir les passages à valider'),
          child: GestureDetector(
            onTap: !isManualPassageValidation
                ? onAutoTap
                : (isManualPassageValidation &&
                        pendingLoyaltyPassagesToConfirm > 0 &&
                        onConfirmPendingPassagesTap != null
                    ? onConfirmPendingPassagesTap
                    : null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: isManualPassageValidation &&
                        pendingLoyaltyPassagesToConfirm > 0
                    ? const LinearGradient(
                        colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                      )
                    : null,
                color: isManualPassageValidation &&
                        pendingLoyaltyPassagesToConfirm > 0
                    ? null
                    : MerchantColors.navyCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                !isManualPassageValidation
                    ? 'Auto'
                    : (pendingLoyaltyPassagesToConfirm > 0
                        ? 'Confirmer ($pendingLoyaltyPassagesToConfirm)'
                        : 'Confirmer'),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isManualPassageValidation &&
                          pendingLoyaltyPassagesToConfirm > 0
                      ? MerchantColors.darkOverlay
                      : MerchantColors.textLightGrey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBox() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.person_add_outlined,
            value: '$connectedClientsThisMonth',
            label: 'Clients connectés',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.loyalty_outlined,
            value: '$validatedPassagesThisMonth',
            label: 'Passages validés',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              MerchantColors.gold.withValues(alpha: MerchantColors.goldBorderAlpha),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MerchantColors.gold, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: MerchantColors.textGrey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Ce mois-ci',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: MerchantColors.gold.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
