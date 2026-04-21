import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selection_colors.dart';

/// Merchant view widget for role selection screen
class MerchantView extends StatelessWidget {
  const MerchantView({
    super.key,
    required this.onDiscover,
    this.onLogin,
  });

  final VoidCallback onDiscover;
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final gapAfterDescription = (screenH * 0.03).clamp(12.0, 24.0);

    return Column(
      children: [
        // Value proposition
        Text(
          'Votre relation clients, vos données,\nvotre indépendance.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: RoleSelectionColors.textLight.withValues(alpha: 0.85),
            fontWeight: FontWeight.w400,
            height: 1.65,
          ),
        ),
        SizedBox(height: gapAfterDescription),

        // Login button (returning merchant)
        if (onLogin != null) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onLogin,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: RoleSelectionColors.primaryGold,
                  width: 1.5,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              child: Text(
                'Se connecter',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: RoleSelectionColors.primaryGold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Discover / onboarding button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onDiscover,
            style: ElevatedButton.styleFrom(
              backgroundColor: RoleSelectionColors.textLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.15),
              elevation: 4,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Découvrir Yuz',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: RoleSelectionColors.bgDark1,
                    ),
                  ),
                  TextSpan(
                    text: 'too',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: RoleSelectionColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
