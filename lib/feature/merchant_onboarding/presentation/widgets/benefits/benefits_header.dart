import 'package:flutter/material.dart';
import 'benefits_colors.dart';

/// Header widget for benefits screen
class BenefitsHeader extends StatelessWidget {
  const BenefitsHeader({
    super.key,
    required this.animationController,
  });

  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animationController,
      child: Column(
        children: [
          Text(
            'Yuztoo, concrètement pour vous',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: BenefitsColors.textLight,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  BenefitsColors.primaryGold.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

