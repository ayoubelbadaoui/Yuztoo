import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Compact bar shown above the form while an automatic notification is being
/// edited: which notification, replay the coachmark guide, cancel.
///
/// The step-by-step explanation itself is the coachmark tour started from
/// `_edit` (see `CoachmarkTour`).
class EditNotificationHelpCard extends StatelessWidget {
  const EditNotificationHelpCard({
    super.key,
    required this.triggerLabel,
    required this.onCancel,
    required this.onShowGuide,
  });

  /// Trigger of the notification being edited (e.g. « Anniversaire »).
  final String triggerLabel;
  final VoidCallback onCancel;
  final VoidCallback onShowGuide;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: MerchantColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, color: MerchantColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode modification',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (triggerLabel.trim().isNotEmpty)
                  Text(
                    '« ${triggerLabel.trim()} »',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Comment modifier ?',
            onPressed: onShowGuide,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.info_outline_rounded,
                color: MerchantColors.gold, size: 19),
          ),
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              onCancel();
            },
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
