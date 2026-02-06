import 'package:flutter/material.dart';
import 'storefront_colors.dart';

/// Navigation tabs for storefront sections
class NavigationTabs extends StatelessWidget {
  const NavigationTabs({
    super.key,
    required this.activeTab,
    this.onTabChanged,
  });

  final String activeTab;
  final ValueChanged<String>? onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TabButton(
                label: 'Accueil',
                isActive: activeTab == 'accueil',
                onTap: () => onTabChanged?.call('accueil'),
              ),
              _TabButton(
                label: 'Horaires',
                isActive: activeTab == 'horaires',
                onTap: () => onTabChanged?.call('horaires'),
              ),
              _TabButton(
                label: 'Actualité',
                isActive: activeTab == 'actualite',
                onTap: () => onTabChanged?.call('actualite'),
              ),
            ],
          ),
        ),
        // Static separator line (always visible, never moves)
        Container(
          height: 1,
          margin: const EdgeInsets.only(top: 16),
          color: StorefrontColors.borderLight,
        ),
      ],
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controller for press feedback (quick scale animation)
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? StorefrontColors.primaryGold.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isActive
                ? Border.all(
                    color: StorefrontColors.primaryGold.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: widget.isActive ? 15 : 14,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive
                      ? StorefrontColors.primaryGold
                      : StorefrontColors.textSecondary,
                  letterSpacing: widget.isActive ? 0.3 : 0.2,
                  height: 1.2,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 12),
              // Animated gold indicator that appears on top of the static border line
              Transform.translate(
                offset: const Offset(0, 13), // Position to align with static border below
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: widget.isActive ? 36 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: StorefrontColors.primaryGold,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: StorefrontColors.primaryGold
                                  .withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 0),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

