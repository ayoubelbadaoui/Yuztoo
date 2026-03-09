import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Cycling "Chargement" → "Chargement." → "Chargement.." → "Chargement..."
///
/// CSS: font-size:16px, color:#999, weight 400, letter-spacing 0.5px.
/// JS:  cycles every 500ms.
class LoadingText extends StatefulWidget {
  const LoadingText({super.key});

  @override
  State<LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<LoadingText> {
  static const _texts = [
    'Chargement',
    'Chargement.',
    'Chargement..',
    'Chargement...',
  ];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _texts.length);
      _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32, minWidth: 180),
      child: Center(
        child: Text(
          _texts[_index],
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: MerchantColors.textGrey,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

