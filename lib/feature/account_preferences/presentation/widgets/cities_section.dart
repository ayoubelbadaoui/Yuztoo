import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// "Villes connectées" section with selectable pills + add button.
class CitiesSection extends StatefulWidget {
  const CitiesSection({super.key});

  @override
  State<CitiesSection> createState() => _CitiesSectionState();
}

class _CitiesSectionState extends State<CitiesSection> {
  final List<_City> _cities = [
    _City('Besancon', true),
    _City('Belfort', false),
  ];

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
          Text(
            'Villes connectées:',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._cities.asMap().entries.map((e) => _buildPill(e.key, e.value)),
              _buildAddButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(int index, _City city) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _cities[index] = _City(city.name, !city.active);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: city.active ? MerchantColors.gold : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          city.name,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: city.active ? Colors.white : MerchantColors.darkOverlay,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        // Placeholder – add city action
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: MerchantColors.gold, width: 2),
        ),
        child: const Icon(Icons.add, color: MerchantColors.gold, size: 20),
      ),
    );
  }
}

class _City {
  _City(this.name, this.active);
  final String name;
  final bool active;
}

