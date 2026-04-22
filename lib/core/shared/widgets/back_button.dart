import 'package:flutter/material.dart';

/// Reusable back button widget with consistent design
class YBackButton extends StatelessWidget {
  const YBackButton({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });

  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF1A2B42),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor ?? const Color(0xFF2A3F5F),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor ?? const Color(0xFFF5F5F5),
          size: 20,
        ),
      ),
    );
  }
}

