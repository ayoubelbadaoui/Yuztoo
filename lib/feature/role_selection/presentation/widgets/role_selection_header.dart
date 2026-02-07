import 'package:flutter/material.dart';
import 'role_selection_colors.dart';
import '../../../../types.dart';
import '../../../../l10n/app_localizations.dart';

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
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: RoleSelectionColors.primaryGold, width: 4),
            boxShadow: [
              BoxShadow(
                color: RoleSelectionColors.primaryGold.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF192D41).withValues(alpha: 0.6),
                RoleSelectionColors.bgDark2.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 60,
            color: RoleSelectionColors.primaryGold,
          ),
        ),
        const SizedBox(height: 32),

        // Brand
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'yuz',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: RoleSelectionColors.textLight,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'too',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: RoleSelectionColors.primaryGold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          AppLocalizations.of(context)!.forThemForYou,
          style: const TextStyle(
            fontSize: 12,
            color: RoleSelectionColors.textGrey,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),

        // Description
        Text(
          AppLocalizations.of(context)!.allTheShops,
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
                text: AppLocalizations.of(context)!.youreUsedTo,
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
          AppLocalizations.of(context)!.welcomeQuestion,
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
    final l10n = AppLocalizations.of(context)!;
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
              label: l10n.merchant,
              isSelected: selectedRole == UserRole.merchant,
              onTap: () => onRoleChanged(UserRole.merchant),
            ),
          ),
          Expanded(
            child: _RoleButton(
              role: UserRole.client,
              label: l10n.client,
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

