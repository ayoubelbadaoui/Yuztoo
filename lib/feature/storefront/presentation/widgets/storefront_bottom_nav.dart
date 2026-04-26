import 'package:flutter/material.dart';
import 'storefront_colors.dart';

/// Bottom navigation bar for storefront
class StorefrontBottomNav extends StatelessWidget {
  const StorefrontBottomNav({
    super.key,
    this.onTabSelected,
  });

  final ValueChanged<String>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: StorefrontColors.navyDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _NavItem(
              icon: Icons.people_outline_rounded,
              label: 'Vos clients',
              onTap: () => onTabSelected?.call('communaute'),
            ),
            _NavItem(
              icon: Icons.notifications_outlined,
              label: 'Rappels',
              onTap: () => onTabSelected?.call('rappels'),
            ),
            _NavItem(
              icon: Icons.storefront_outlined,
              label: 'Vitrine',
              isActive: true,
              onTap: () => onTabSelected?.call('vitrine'),
            ),
            _NavItem(
              icon: Icons.local_offer_outlined,
              label: 'Promotions',
              onTap: () => onTabSelected?.call('promotions'),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              onTap: () => onTabSelected?.call('profil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        margin: EdgeInsets.only(bottom: isActive ? 4 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: StorefrontColors.primaryGold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: StorefrontColors.primaryGold.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: StorefrontColors.navyDark,
                  size: 24,
                ),
              )
            else
              Icon(
                icon,
                color: StorefrontColors.primaryGold,
                size: 24,
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: StorefrontColors.primaryGold.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

