part of 'client_type_details.dart';

extension _ClientTypeDetailsUi on ClientTypeDetails {
  Widget _buildGratuit() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _detailBox,
      child: Text(
        'Pour respecter vos clients, limitez-vous à 2 / 3 messages par semaine maximum',
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: MerchantColors.textLightGrey,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPremium() {
    final targets = ['VIP', 'Soutien', 'Habitué'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _detailBox,
      child: Column(
        children: [
          Text(
            'Quels clients voulez-vous cibler?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(targets.length, (i) {
              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                child: _selectableChip(
                  targets[i],
                  isSelected: selectedTargetIndex == i,
                  onTap: () => onTargetChanged(i),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          _filterRow('Clients actifs depuis', '15/01/2025'),
          const SizedBox(height: 6),
          _filterRow('Clients inactifs depuis', '15/01/2024'),
          const SizedBox(height: 6),
          _filterRow('Clients connectés depuis', '01/01/2025'),
          const SizedBox(height: 6),
          _filterRow('Top X clients du mois', 'Top 10'),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: 'Vous avez ciblé ',
                  style:
                      GoogleFonts.outfit(fontSize: 11, color: Colors.white)),
              TextSpan(
                  text: 'X',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.gold)),
              TextSpan(
                  text: ' clients\nsur un total de ',
                  style:
                      GoogleFonts.outfit(fontSize: 11, color: Colors.white)),
              TextSpan(
                  text: 'X',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.gold)),
              TextSpan(
                  text: ' clients connectés',
                  style:
                      GoogleFonts.outfit(fontSize: 11, color: Colors.white)),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tarif: 5 \u20AC HT ou inclus avec abonnement premium',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: MerchantColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayant() {
    final distances = ['Villes', 'Quartier', 'Proche de vous'];
    final counts = ['500', '200', 'Max 100'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _detailBox,
      child: Column(
        children: [
          Text(
            'A quelle distance autour de vous?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(distances.length, (i) {
              return _distanceOption(
                distances[i],
                counts[i],
                isSelected: selectedDistanceIndex == i,
                onTap: () => onDistanceChanged(i),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            'Yuztoo ne contacte jamais vos seuls clients ni sans leurs autorisations.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: MerchantColors.textLightGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'Tarif: 0.10cts HT/client soit ',
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: MerchantColors.textLightGrey),
              ),
              TextSpan(
                text: '50\u20AC',
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: MerchantColors.gold),
              ),
              TextSpan(
                text: ' pour cette notification',
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: MerchantColors.textLightGrey),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _selectableChip(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? MerchantColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? MerchantColors.gold
                : MerchantColors.textGrey.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? MerchantColors.darkOverlay
                : MerchantColors.textLightGrey,
          ),
        ),
      ),
    );
  }

  Widget _filterRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: MerchantColors.cream.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _distanceOption(
    String label,
    String count, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? MerchantColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? MerchantColors.gold
                    : MerchantColors.textGrey.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? MerchantColors.darkOverlay
                    : MerchantColors.textLightGrey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: count,
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.gold),
              ),
              TextSpan(
                text: ' clients',
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
