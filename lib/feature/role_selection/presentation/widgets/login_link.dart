import 'package:flutter/material.dart';
import 'role_selection_colors.dart';

/// Login link widget for role selection screen
class LoginLink extends StatelessWidget {
  const LoginLink({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Text(
        'Vous avez déjà un compte ?',
        style: TextStyle(
          fontSize: 14,
          color: RoleSelectionColors.textGrey,
        ),
      ),
    );
  }
}

