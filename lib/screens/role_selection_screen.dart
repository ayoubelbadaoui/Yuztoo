import 'package:flutter/material.dart';
import '../theme.dart';
import '../types.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key, required this.onSelectRole});

  final ValueChanged<UserRole> onSelectRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: YColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: YColors.secondary,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text('Y', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            Text('Bienvenue sur Yuztoo', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text(
              'Choisissez votre profil pour continuer',
              textAlign: TextAlign.center,
              style: TextStyle(color: YColors.muted),
            ),
            const SizedBox(height: 28),
            _RoleCard(
              icon: Icons.person_outline,
              title: 'Client',
              description: 'Découvrez les commerces, collectez des points et profitez des promotions',
              onTap: () => onSelectRole(UserRole.client),
              badgeColor: Colors.white,
              iconColor: YColors.primary,
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.store_mall_directory_outlined,
              title: 'Commerçant',
              description: 'Gérez votre commerce, fidélisez vos clients et augmentez vos ventes',
              onTap: () => onSelectRole(UserRole.merchant),
              badgeColor: YColors.secondary.withOpacity(0.1),
              iconColor: YColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.badgeColor,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color badgeColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: YColors.muted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
