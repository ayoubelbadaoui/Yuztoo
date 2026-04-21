import 'package:flutter/material.dart';
import '../../../types.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../feature/storefront/application/widgets.dart';

class YBottomNav extends StatelessWidget {
  const YBottomNav({
    super.key,
    required this.role,
    required this.activeTab,
    required this.onTabChange,
    this.notificationBadgeCount = 0,
  });

  final UserRole role;
  final String activeTab;
  final ValueChanged<String> onTabChange;

  /// Number shown on the notifications tab badge. 0 = hidden.
  final int notificationBadgeCount;

  @override
  Widget build(BuildContext context) {
    final tabs = role == UserRole.client
        ? [
            const _TabItem(id: 'home', label: 'Accueil', icon: Icons.home_outlined),
            const _TabItem(id: 'discovery', label: 'Découvrir', icon: Icons.search),
            _TabItem(
              id: 'notifications',
              label: 'Alertes',
              icon: Icons.notifications_none_rounded,
              badgeCount: notificationBadgeCount,
            ),
            const _TabItem(id: 'loyalty', label: 'Fidélité', icon: Icons.star_border),
            const _TabItem(id: 'profile', label: 'Profil', icon: Icons.person_outline),
          ]
        : const [
            _TabItem(id: 'communaute', label: 'Vos clients', icon: Icons.people_outline),
            _TabItem(id: 'rappels', label: 'Rappels', icon: Icons.notifications_outlined),
            _TabItem(id: 'storefront', label: 'Vitrine', icon: Icons.storefront),
            _TabItem(id: 'promotions', label: 'Promotions', icon: Icons.local_offer_outlined),
            _TabItem(id: 'profile', label: 'Profil', icon: Icons.person_outline),
          ];

    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        border: Border(
          top: BorderSide(
            color: MerchantColors.gold.withValues(alpha: MerchantColors.goldBorderAlpha),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: tabs.map((tab) {
              final isActive = tab.id == activeTab;
              return Expanded(
                child: _MerchantNavItem(
                  icon: tab.icon,
                  label: tab.label,
                  isActive: isActive,
                  badgeCount: tab.badgeCount,
                  onTap: () => onTabChange(tab.id),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MerchantNavItem extends StatefulWidget {
  const _MerchantNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_MerchantNavItem> createState() => _MerchantNavItemState();
}

class _MerchantNavItemState extends State<_MerchantNavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Active background pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: widget.isActive ? 40 : 0,
                      height: widget.isActive ? 40 : 0,
                      decoration: BoxDecoration(
                        color: StorefrontColors.primaryGold,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: widget.isActive
                            ? [
                                BoxShadow(
                                  color: StorefrontColors.primaryGold
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                    ),
                    // Icon
                    Icon(
                      widget.icon,
                      color: widget.isActive
                          ? StorefrontColors.navyDark
                          : StorefrontColors.primaryGold,
                      size: 24,
                    ),
                    // Badge
                    if (widget.badgeCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4A017),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: StorefrontColors.primaryGold.withValues(
                    alpha: widget.isActive ? 1.0 : 0.7,
                  ),
                  letterSpacing: 0.1,
                  height: 1.1,
                ),
                child: Text(
                  widget.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.id,
    required this.label,
    required this.icon,
    this.badgeCount = 0,
  });

  final String id;
  final String label;
  final IconData icon;
  final int badgeCount;
}
