import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../types.dart';

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
              id: 'dashboard',
              label: 'Tableau',
              icon: Icons.dashboard_outlined,
            ),
            _TabItem(
              id: 'clients',
              label: 'Clients',
              icon: Icons.group_outlined,
            ),
            _TabItem(
              id: 'stats',
              label: 'Stats',
              icon: Icons.bar_chart_outlined,
            ),
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
          ];

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

class _TabItem {
  const _TabItem({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}
