part of 'client_type_details.dart';

// Segment definitions: key → display label
const _kSegments = [
  ('vip', 'VIP'),
  ('soutien', 'Soutien'),
  ('habitue', 'Habitué'),
];

extension _ClientTypeDetailsUi on ClientTypeDetails {
  Widget _buildGratuit() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _detailBox,
      child: Text(
        'Pour vos envois manuels depuis Rappels, le plafond du plan gratuit '
        'est de 5 notifications par fenêtre glissante de 7 jours (compteur X/5 '
        'dans Rappels). Pour cette diffusion gratuite, évitez aussi de '
        'sur-solliciter vos abonnés.',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _detailBox,
      child: Column(
        children: [
          Text(
            'Quels clients voulez-vous cibler ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Multi-select segment chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _kSegments.map((seg) {
              final isSelected = selectedSegments.contains(seg.$1);
              return GestureDetector(
                onTap: () => onSegmentToggled(seg.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MerchantColors.gold
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? MerchantColors.gold
                          : MerchantColors.textGrey.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    seg.$2,
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
            }).toList(),
          ),
          const SizedBox(height: 14),
          _filterRow('Clients actifs depuis', '15/01/2025'),
          const SizedBox(height: 6),
          _filterRow('Clients inactifs depuis', '15/01/2024'),
          const SizedBox(height: 6),
          _filterRow('Clients connectés depuis', '01/01/2025'),
          const SizedBox(height: 6),
          _filterRow('Top X clients du mois', 'Top 10'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_rounded,
                  size: 11, color: MerchantColors.textGrey),
              const SizedBox(width: 4),
              Text(
                'Filtres avancés bientôt disponibles',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: MerchantColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: 'Vous avez ciblé ',
                  style:
                      GoogleFonts.outfit(fontSize: 11, color: Colors.white)),
              TextSpan(
                  text: selectedSegments.isEmpty
                      ? 'tous'
                      : '${selectedSegments.length} segment${selectedSegments.length > 1 ? 's' : ''}',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.gold)),
              TextSpan(
                  text: ' — Tarif: 5 € HT ou inclus avec abonnement premium',
                  style:
                      GoogleFonts.outfit(fontSize: 11, color: Colors.white)),
            ]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPayant() {
    const zones = PromotionZone.values;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _detailBox,
      child: Column(
        children: [
          Text(
            'À quelle distance autour de vous ?',
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
            children: List.generate(zones.length, (i) {
              return _distanceOption(
                zones[i].label,
                '${zones[i].estimatedReach}',
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
                text:
                    '${(zones[selectedDistanceIndex].estimatedReach * 0.10).toStringAsFixed(0)}€',
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: MerchantColors.gold),
              ),
              TextSpan(
                text: ' pour cette zone',
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                style:
                    GoogleFonts.outfit(fontSize: 10, color: Colors.white),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
