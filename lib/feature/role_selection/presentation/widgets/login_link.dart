import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selection_colors.dart';

/// Login link for the merchant role footer.
class LoginLink extends StatelessWidget {
  const LoginLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: RoleSelectionColors.textGrey,
          ),
          children: [
            const TextSpan(text: 'Vous avez déjà un compte ? '),
            TextSpan(
              text: 'Se connecter',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RoleSelectionColors.primaryGold,
                decoration: TextDecoration.underline,
                decorationColor: RoleSelectionColors.primaryGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
