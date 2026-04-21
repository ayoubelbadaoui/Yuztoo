import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Gratuit pour démarrer, sans engagement.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: BenefitsColors.textGrey,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
