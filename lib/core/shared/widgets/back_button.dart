import 'package:flutter/material.dart';

/// Canonical Yuztoo back button. Gold icon, 44×44 touch target, no decoration.
/// Use on both dark (navy) and light screens — pass [iconColor] to match the screen.
class YBackButton extends StatelessWidget {
  const YBackButton({
    super.key,
    required this.onPressed,
    this.iconColor,
  });

  final VoidCallback onPressed;

  /// Defaults to gold (`Color(0xFFD4A017)`).
  /// Pass `StorefrontColors.primaryGold` on light screens or `Colors.white` if needed.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor ?? const Color(0xFFD4A017),
          size: 20,
        ),
      ),
    );
  }
}
