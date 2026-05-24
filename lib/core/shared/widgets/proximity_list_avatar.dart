import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/merchant_colors.dart';

/// Photo (or initials / icon) for BLE proximity lists and sheets.
class ProximityListAvatar extends StatelessWidget {
  const ProximityListAvatar({
    super.key,
    this.imageUrl,
    required this.label,
    this.size = 48,
    this.fallbackIcon,
  });

  final String? imageUrl;
  final String label;
  final double size;
  final IconData? fallbackIcon;

  String get _initials {
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return label.trim().isNotEmpty ? label.trim()[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MerchantColors.gold.withValues(alpha: 0.12),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackContent(),
            )
          : _fallbackContent(),
    );
  }

  Widget _fallbackContent() {
    return Center(
      child: fallbackIcon != null
          ? Icon(
              fallbackIcon,
              color: MerchantColors.gold,
              size: size * 0.48,
            )
          : Text(
              _initials,
              style: GoogleFonts.outfit(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
              ),
            ),
    );
  }
}
