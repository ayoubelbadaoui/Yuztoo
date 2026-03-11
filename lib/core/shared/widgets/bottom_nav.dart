import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../types.dart';
import '../../../feature/storefront/presentation/widgets/storefront_colors.dart';

class YBottomNav extends StatelessWidget {
  const YBottomNav({
    super.key,
    required this.role,
    required this.activeTab,
    required this.onTabChange,
  });

  final UserRole role;
  final String activeTab;
  final ValueChanged<String> onTabChange;

  @override
  Widget build(BuildContext context) {
    final tabs = role == UserRole.client
        ? const [
            _TabItem(id: 'home', label: 'Accueil', icon: Icons.home_outlined),
            _TabItem(id: 'discovery', label: 'Découvrir', icon: Icons.search),
            _TabItem(id: 'loyalty', label: 'Fidélité', icon: Icons.star_border),
            _TabItem(
              id: 'messages',
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
            ),
            _TabItem(
              id: 'profile',
              label: 'Profil',
              icon: Icons.person_outline,
            ),
          ]
        : const [
            _TabItem(
              id: 'communaute',
              label: 'Vos clients',
              icon: Icons.people_outline,
            ),
            _TabItem(
              id: 'rappels',
              label: 'Rappels',
              icon: Icons.notifications_outlined,
            ),
            _TabItem(
              id: 'storefront',
              label: 'Vitrine',
              icon: Icons.storefront,
            ),
            _TabItem(
              id: 'promotions',
              label: 'Promotions',
              icon: Icons.local_offer_outlined,
            ),
            _TabItem(
              id: 'profile',
              label: 'Profil',
              icon: Icons.person_outline,
            ),
          ];

    // Use storefront design for merchants, default for clients
    final isMerchant = role == UserRole.merchant;
    
    if (isMerchant) {
      return Container(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1F33), // matches header
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
                    onTap: () => onTabChange(tab.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    // Client navigation (original design)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: YColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tab) {
              final isActive = tab.id == activeTab;
              final color = isActive ? YColors.secondary : YColors.muted;
              return GestureDetector(
                onTap: () => onTabChange(tab.id),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, color: color, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
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
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_MerchantNavItem> createState() => _MerchantNavItemState();
}

class _MerchantNavItemState extends State<_MerchantNavItem> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
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
              // Icon container with stable size (smaller)
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background container (only visible when active)
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
                                  color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                    ),
                    // Icon (always same size, stable)
                    Icon(
                      widget.icon,
                      color: widget.isActive
                          ? StorefrontColors.navyDark
                          : StorefrontColors.primaryGold,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Label with smooth transition (smaller)
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
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
  const _TabItem({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}
