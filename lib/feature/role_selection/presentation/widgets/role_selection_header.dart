import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selection_colors.dart';
import '../../../../types.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/shared/widgets/app_logo.dart';

/// Header widget for role selection screen
class RoleSelectionHeader extends StatelessWidget {
  const RoleSelectionHeader({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final logoSize = (screenH * 0.18).clamp(100.0, 180.0);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        AppLogo(
          size: logoSize,
          fallback: Icon(
            Icons.store,
            size: logoSize * 0.45,
            color: RoleSelectionColors.primaryGold,
          ),
        ),
        SizedBox(height: (screenH * 0.03).clamp(12.0, 28.0)),

        // Tagline line 1 — white part
        Text(
          l10n?.allTheShops ?? 'Tous vos commerces préférés,',
          style: GoogleFonts.outfit(
            fontSize: 17,
            color: RoleSelectionColors.textLight,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),

        // Tagline line 2 — gold emphasis
        Text(
          l10n?.youreUsedTo ?? 'à portée de main.',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: RoleSelectionColors.primaryGold,
          ),
        ),
        const SizedBox(height: 20),

        // Role question
        Text(
          l10n?.welcomeQuestion ?? 'Bienvenue — vous êtes ?',
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: RoleSelectionColors.textLight.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),

        // Role Toggle
        RoleToggle(
          selectedRole: selectedRole,
          onRoleChanged: onRoleChanged,
        ),
      ],
    );
  }
}

/// Role toggle widget
class RoleToggle extends StatelessWidget {
  const RoleToggle({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: RoleSelectionColors.bgDark2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: RoleSelectionColors.primaryGold.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleButton(
              role: UserRole.merchant,
              label: l10n?.merchant ?? 'Commerçant',
              isSelected: selectedRole == UserRole.merchant,
              onTap: () => onRoleChanged(UserRole.merchant),
            ),
          ),
          Expanded(
            child: _RoleButton(
              role: UserRole.client,
              label: l10n?.client ?? 'Client',
              isSelected: selectedRole == UserRole.client,
              onTap: () => onRoleChanged(UserRole.client),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.role,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? RoleSelectionColors.primaryGold
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: RoleSelectionColors.primaryGold
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected
                ? RoleSelectionColors.bgDark1
                : RoleSelectionColors.textLight.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

