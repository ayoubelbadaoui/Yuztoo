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
        SizedBox(
          width: double.infinity,
          child: Text(
            l10n?.allTheShops ?? 'Tous vos commerces préférés,',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              color: RoleSelectionColors.textLight,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Tagline line 2 — gold emphasis
        SizedBox(
          width: double.infinity,
          child: Text(
            l10n?.youreUsedTo ?? 'à portée de main.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: RoleSelectionColors.primaryGold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Role question
        SizedBox(
          width: double.infinity,
          child: Text(
            l10n?.welcomeQuestion ?? 'Bienvenue — vous êtes ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: RoleSelectionColors.textLight.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
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

/// Role toggle — segmented control with ONE sliding gold pill.
///
/// The previous version faded a pill out on one side while fading another in
/// on the other (two half-transparent pills mid-animation) and switched the
/// label from regular to bold, shifting the text: it read as glitchy.
class RoleToggle extends StatelessWidget {
  const RoleToggle({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  static const Duration _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final merchantSelected = selectedRole == UserRole.merchant;
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
      child: Stack(
        children: [
          // The single pill, sliding under the labels.
          Positioned.fill(
            child: AnimatedAlign(
              duration: _duration,
              curve: Curves.easeOutCubic,
              alignment: merchantSelected
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: RoleSelectionColors.primaryGold,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: RoleSelectionColors.primaryGold
                            .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _RoleButton(
                  label: l10n?.merchant ?? 'Commerçant',
                  isSelected: merchantSelected,
                  onTap: () => onRoleChanged(UserRole.merchant),
                ),
              ),
              Expanded(
                child: _RoleButton(
                  label: l10n?.client ?? 'Client',
                  isSelected: !merchantSelected,
                  onTap: () => onRoleChanged(UserRole.client),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isSelected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
          // Same weight in both states (no text shift); only the colour
          // animates, in step with the sliding pill.
          child: AnimatedDefaultTextStyle(
            duration: RoleToggle._duration,
            curve: Curves.easeOutCubic,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? RoleSelectionColors.bgDark1
                  : RoleSelectionColors.textLight.withValues(alpha: 0.7),
            ),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
