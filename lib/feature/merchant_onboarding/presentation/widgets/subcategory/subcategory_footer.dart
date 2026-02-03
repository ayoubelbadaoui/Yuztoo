import 'package:flutter/material.dart';
import 'subcategory_colors.dart';

/// Footer widget for subcategory selection screen
class SubcategoryFooter extends StatelessWidget {
  const SubcategoryFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SubcategoryColors.bgDark2.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SubcategoryColors.primaryGold.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: SubcategoryColors.primaryGold.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ce choix nous permet d\'adapter nos services, vous pourrez le modifier à tout moment.',
                style: TextStyle(
                  fontSize: 12,
                  color: SubcategoryColors.textGrey.withOpacity(0.9),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

