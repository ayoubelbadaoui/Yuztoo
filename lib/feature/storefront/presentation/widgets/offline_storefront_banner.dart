import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'storefront_colors.dart';

/// Shown on the merchant's own vitrine while it is unpublished. Only the
/// "Mettre en ligne" button publishes; the close button just hides the card.
class OfflineStorefrontBanner extends StatelessWidget {
  const OfflineStorefrontBanner({
    super.key,
    required this.isPublishing,
    required this.onPublish,
    required this.onDismiss,
  });

  final bool isPublishing;
  final VoidCallback onPublish;
  final VoidCallback onDismiss;

  static const Color _amber = Color(0xFFB7791F);
  static const Color _amberSoft = Color(0xFFFFF4DC);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: StorefrontColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _amber.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: StorefrontColors.navyDark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _amberSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility_off_rounded,
                    color: _amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Vitrine hors ligne',
                                style: GoogleFonts.outfit(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: StorefrontColors.navyDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Les clients ne voient pas encore votre commerce. '
                          'Vous pouvez continuer à modifier votre vitrine.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            height: 1.4,
                            color: StorefrontColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Masquer',
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: StorefrontColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isPublishing ? null : onPublish,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: StorefrontColors.navyDark,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        StorefrontColors.navyDark.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isPublishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.rocket_launch_rounded,
                          size: 18,
                          color: StorefrontColors.primaryGold,
                        ),
                  label: Text(
                    isPublishing ? 'Mise en ligne…' : 'Mettre en ligne',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: OfflineStorefrontBanner._amberSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: OfflineStorefrontBanner._amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Invisible',
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: OfflineStorefrontBanner._amber,
            ),
          ),
        ],
      ),
    );
  }
}
