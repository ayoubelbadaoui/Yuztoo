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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 3,
              maxLength: 200,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: const Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: isEditing
                    ? 'Modifiez votre notification...'
                    : 'Écrivez votre notification ici...',
                hintStyle: GoogleFonts.outfit(
                    fontSize: 14, color: const Color(0xFFAAAAAA)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                counterStyle: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF999999),
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

