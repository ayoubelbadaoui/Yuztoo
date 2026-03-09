import 'package:flutter/material.dart';

import 'storefront_colors.dart';

/// Custom gold-themed toggle switch with animated thumb.
///
/// Active = gold track, inactive = grey track with border.
/// Pass [onChanged] = null to disable.
class GoldSwitch extends StatelessWidget {
  const GoldSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;
    final trackColor = value
        ? StorefrontColors.primaryGold
        : (isDisabled ? Colors.grey[200]! : const Color(0xFFCBCBCB));

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: trackColor,
          border: value
              ? null
              : Border.all(color: Colors.grey[350]!, width: 1),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

