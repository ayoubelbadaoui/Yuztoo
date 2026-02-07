import 'package:flutter/material.dart';
import 'role_selection_colors.dart';

/// Merchant view widget for role selection screen
class MerchantView extends StatelessWidget {
  const MerchantView({
    super.key,
    required this.onDiscover,
  });

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Description Text
        const Text(
          'Votre relation clients, vos données,\nvotre indépendance.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: RoleSelectionColors.textLight,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),

        // Discover Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onDiscover,
            style: ElevatedButton.styleFrom(
              backgroundColor: RoleSelectionColors.textLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.1),
              elevation: 4,
            ),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Découvrir Yuz',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: RoleSelectionColors.bgDark1,
                    ),
                  ),
                  TextSpan(
                    text: 'too',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

