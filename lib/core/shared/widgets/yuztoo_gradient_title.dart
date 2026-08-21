import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// White → gold header title matching Accueil « Mon carnet ».
///
/// Use for client (and merchant) shell tab titles so Découvrir / Fidélité /
/// Alertes / Mon profil / Vos clients share one production look.
class YuztooGradientTitle extends StatelessWidget {
  const YuztooGradientTitle(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w600,
    this.textAlign,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;

  static const LinearGradient gradient = LinearGradient(
    colors: [Color(0xFFF5F5F5), Color(0xFFD4A017)],
    stops: [0.45, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    );
  }
}
