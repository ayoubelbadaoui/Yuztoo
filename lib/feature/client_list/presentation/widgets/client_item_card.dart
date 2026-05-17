import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/merchant_client_row.dart';

/// A single client row: avatar (real photo or initials) + name/subtitle +
/// segment badge + arrow.
class ClientItemCard extends StatelessWidget {
  const ClientItemCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.photoUrl,
    this.segment,
    this.onTap,
  });

  final String name;
  final String subtitle;

  /// When non-null/non-empty, the client's real avatar is shown. Falls back
  /// to a coloured circle of initials when missing or if the network image
  /// fails to load.
  final String? photoUrl;
  final ClientSegment? segment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final segColor = _segmentColor(segment);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // ── avatar (real photo if available, else initials) ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: segColor.withValues(alpha: 0.12),
                border: Border.all(
                    color: segColor.withValues(alpha: 0.6), width: 1.5),
              ),
              child: ClipOval(
                child: hasPhoto
                    ? Image.network(
                        photoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: segColor,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: segColor,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // ── name + subtitle ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: MerchantColors.textGrey,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── segment badge ──
            if (segment != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: segColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: segColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  segment!.label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: segColor,
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // ── forward arrow ──
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: MerchantColors.gold.withValues(alpha: 0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Color _segmentColor(ClientSegment? seg) {
    switch (seg) {
      case ClientSegment.vip:
        return const Color(0xFFFFD700);
      case ClientSegment.habitue:
        return const Color(0xFF4CAF50);
      case ClientSegment.nouveau:
        return const Color(0xFF64B5F6);
      case ClientSegment.inactif:
        return Colors.grey;
      // 'abonne' is legacy — no longer produced by MerchantClientRow.segment.
      // Kept here as a safety fallback so existing cached data doesn't crash.
      case ClientSegment.abonne:
      case null:
        return const Color(0xFF64B5F6); // treat like 'nouveau' visually
    }
  }
}
