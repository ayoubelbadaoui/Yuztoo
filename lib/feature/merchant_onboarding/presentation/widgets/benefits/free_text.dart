import 'package:flutter/material.dart';
import 'benefits_colors.dart';

/// Free text widget for benefits screen
class FreeText extends StatelessWidget {
  const FreeText({
    super.key,
    required this.animationController,
  });

  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animationController,
      child: const Text(
        'Gratuit pour démarrer, sans engagement.',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: BenefitsColors.textGrey,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

