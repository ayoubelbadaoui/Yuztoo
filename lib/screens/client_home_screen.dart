import 'package:flutter/material.dart';
import '../theme.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onNavigate: onNavigate),
          const SizedBox(height: 12),
          _QuickActions(onNavigate: onNavigate),
          const SizedBox(height: 16),
          _Promotions(onNavigate: onNavigate),
          const SizedBox(height: 16),
          _NearbyStores(onNavigate: onNavigate),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNavigate});
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: const BoxDecoration(color: YColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour,',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Mohammed',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              IconButton(
                onPressed: () => onNavigate('notifications'),
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            onTap: () => onNavigate('discovery'),
            decoration: const InputDecoration(
              hintText: 'Rechercher un commerce...',
              prefixIcon: Icon(Icons.search, color: YColors.muted),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickAction(
                label: 'Scanner',
                icon: Icons.qr_code_rounded,
                background: YColors.secondary,
                iconColor: Colors.white,
                onTap: () => onNavigate('qr-scanner'),
              ),
              _QuickAction(
                label: 'Fidélité',
                icon: Icons.star_border,
                background: YColors.accent,
                iconColor: YColors.secondary,
                onTap: () => onNavigate('loyalty'),
              ),
              _QuickAction(
                label: 'Offres',
                icon: Icons.card_giftcard,
                background: YColors.accent,
                iconColor: YColors.primary,
                onTap: () => onNavigate('discovery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration:
                BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: YColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Promotions extends StatelessWidget {
  const _Promotions({required this.onNavigate});
  final ValueChanged<String> onNavigate;

  static final promos = [
    {
      'title': '20% de réduction',
      'store': 'Café Central',
      'expires': '2 jours'
    },
    {
      'title': 'Café offert',
      'store': 'Pâtisserie Délice',
      'expires': '5 jours'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Promotions actives',
                  style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                  onPressed: () => onNavigate('discovery'),
                  child: const Text('Tout voir')),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: promos
                .map(
                  (promo) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onNavigate('store-profile'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: YColors.secondary.withAlpha(26),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.card_giftcard,
                                        color: YColors.secondary),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(promo['title']!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 2),
                                      Text(promo['store']!,
                                          style: const TextStyle(
                                              color: YColors.muted,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: YColors.secondary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(promo['expires']!,
                                    style: const TextStyle(
                                        color: YColors.secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Store {
  final String name;
  final String category;
  final int points;
  final String image;
  final String distance;

  const _Store({
    required this.name,
    required this.category,
    required this.points,
    required this.image,
    required this.distance,
  });
}

class _NearbyStores extends StatelessWidget {
  const _NearbyStores({required this.onNavigate});
  final ValueChanged<String> onNavigate;

  static const stores = [
    _Store(
      name: 'Café Central',
      category: 'Restaurant',
      points: 120,
      image: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400',
      distance: '0.5 km',
    ),
    _Store(
      name: 'Pharmacie El Amane',
      category: 'Santé',
      points: 80,
      image:
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400',
      distance: '1.2 km',
    ),
    _Store(
      name: 'Pâtisserie Délice',
      category: 'Boulangerie',
      points: 45,
      image:
          'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=400',
      distance: '0.8 km',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commerces à proximité',
                  style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                  onPressed: () => onNavigate('discovery'),
                  child: const Text('Tout voir')),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: stores
                .map(
                  (store) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => onNavigate('store-profile'),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 96,
                              height: 96,
                              child:
                                  Image.network(store.image, fit: BoxFit.cover),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(store.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.grey.shade100,
                                            border: Border.all(
                                                color: YColors.border),
                                          ),
                                          child: Text(store.category,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.place,
                                            size: 14, color: YColors.muted),
                                        const SizedBox(width: 4),
                                        Text(store.distance,
                                            style: const TextStyle(
                                                color: YColors.muted,
                                                fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 16, color: YColors.secondary),
                                        const SizedBox(width: 4),
                                        Text('${store.points} points',
                                            style: const TextStyle(
                                                color: YColors.secondary,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
