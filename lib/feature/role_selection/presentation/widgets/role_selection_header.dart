import 'package:flutter/material.dart';
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
    final logoSize = (screenH * 0.35).clamp(250.0, 350.0);
    
    return Column(
      children: [
        // Logo
        AppLogo(
          size: logoSize,
          fallback: Icon(
            Icons.store,
            size: logoSize * 0.45,
            color: RoleSelectionColors.primaryGold,
          ),
        ),
        SizedBox(height: (screenH * 0.04).clamp(24.0, 36.0)),

        // Description
        Text(
          AppLocalizations.of(context)?.allTheShops ?? 'All the shops',
          style: const TextStyle(
            fontSize: 17,
            color: RoleSelectionColors.textLight,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),

        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: AppLocalizations.of(context)?.youreUsedTo ?? '"You\'re used" to',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: RoleSelectionColors.primaryGold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Question
        Text(
          AppLocalizations.of(context)?.welcomeQuestion ?? 'Bienvenue, Vous êtes ?',
          style: const TextStyle(
            fontSize: 16,
            color: RoleSelectionColors.textLight,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: RoleSelectionColors.bgDark2.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: RoleSelectionColors.primaryGold.withValues(alpha: 0.12),
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
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? RoleSelectionColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? RoleSelectionColors.bgDark1 : RoleSelectionColors.textLight,
          ),
        ),
      ),
    );
  }
}

