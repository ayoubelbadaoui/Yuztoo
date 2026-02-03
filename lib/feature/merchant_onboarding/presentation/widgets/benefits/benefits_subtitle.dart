import 'package:flutter/material.dart';
import 'benefits_colors.dart';

/// Subtitle widget for benefits screen
class BenefitsSubtitle extends StatelessWidget {
  const BenefitsSubtitle({
    super.key,
    required this.animationController,
  });

  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animationController,
      child: const Text(
        'Restez dans la poche de vos clients',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          color: BenefitsColors.textLight,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

