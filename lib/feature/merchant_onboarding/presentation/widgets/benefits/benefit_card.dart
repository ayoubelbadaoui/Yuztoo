import 'package:flutter/material.dart';
import 'benefits_colors.dart';
import '../../../domain/entities/merchant_benefit.dart';

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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + animationDelay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: BenefitsColors.bgDark2.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BenefitsColors.borderColor.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              benefit.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BenefitsColors.primaryGold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              benefit.description,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: BenefitsColors.textLight,
                height: 1.5,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }
}

