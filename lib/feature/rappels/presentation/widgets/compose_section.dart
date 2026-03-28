import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import 'step_header.dart';

/// Step 1 – compose notification text.
class ComposeSection extends StatelessWidget {
  const ComposeSection({
    super.key,
    required this.controller,
    required this.isEditing,
    this.onCancelEdit,
  });

  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback? onCancelEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _sectionBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            step: 1,
            title: 'Votre message',
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: MerchantColors.navyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 3,
              maxLength: 200,
              cursorColor: MerchantColors.gold,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: MerchantColors.textLightGrey,
              ),
              decoration: InputDecoration(
                hintText: isEditing
                    ? 'Modifiez votre notification...'
                    : 'Écrivez votre notification ici...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 14,
                  color: MerchantColors.textGrey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                counterStyle: GoogleFonts.outfit(
                  fontSize: 11,
                  color: MerchantColors.textGrey,
                ),
              ),
            ),
          ),
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: onCancelEdit,
                child: Text(
                  'Annuler la modification',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MerchantColors.textGrey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration _sectionBorder() {
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
          width: 1,
        ),
      ),
    );
  }
}

