import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'benefits_colors.dart';
import '../../../domain/entities/merchant_benefit.dart';

/// Icon per benefit index — presentation layer only, domain stays pure.
const _benefitIcons = [
  Icons.people_rounded,
  Icons.notifications_active_rounded,
  Icons.loyalty_rounded,
  Icons.handshake_rounded,
  Icons.open_in_new_rounded,
];

/// Benefit card widget
class BenefitCard extends StatelessWidget {
  const BenefitCard({
    super.key,
    required this.benefit,
    required this.animationDelay,
  });

  final MerchantBenefit benefit;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    final index = animationDelay ~/ 40; // recover index from delay
    final icon = index < _benefitIcons.length
        ? _benefitIcons[index]
        : Icons.star_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + animationDelay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BenefitsColors.bgDark2.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BenefitsColors.borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BenefitsColors.primaryGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: BenefitsColors.primaryGold,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BenefitsColors.primaryGold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    benefit.description,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: BenefitsColors.textLight.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
