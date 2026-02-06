import 'package:flutter/material.dart';
import '../../../theme.dart';

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen(
      {super.key,
      required this.onBack,
      required this.onMessage,
      required this.onReserve});

  final VoidCallback onBack;
  final VoidCallback onMessage;
  final VoidCallback onReserve;

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen>
    with SingleTickerProviderStateMixin {
  final promotions = const [
    {
      'title': '20% de réduction',
      'description': 'Sur tous les plats',
      'validUntil': '31 Jan 2026'
    },
    {
      'title': 'Café offert',
      'description': 'Pour toute commande',
      'validUntil': '15 Feb 2026'
    },
  ];

  final reviews = const [
    {
      'author': 'Sarah M.',
      'rating': 5,
      'comment': 'Excellent service et produits de qualité !',
      'date': '3 Jan 2026'
    },
    {
      'author': 'Ahmed K.',
      'rating': 4,
      'comment': 'Très bon rapport qualité-prix',
      'date': '1 Jan 2026'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: Image.network(
                  'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                left: 12,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(backgroundColor: Colors.white70),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: YColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('120 points',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Café Central',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.star, size: 16, color: YColors.secondary),
                    SizedBox(width: 4),
                    Text('4.5 (128 avis)',
                        style: TextStyle(color: YColors.muted)),
                    SizedBox(width: 12),
                    Icon(Icons.place, size: 16, color: YColors.muted),
                    SizedBox(width: 4),
                    Text('0.5 km', style: TextStyle(color: YColors.muted)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Restaurant & Café traditionnel marocain. Spécialités locales et pâtisseries fraîches tous les jours.',
                  style: TextStyle(color: YColors.muted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onMessage,
                        icon: const Icon(Icons.message_outlined),
                        label: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onReserve,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Réserver'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.access_time,
                    title: 'Horaires',
                    subtitle: 'Lun - Sam: 8h00 - 22h00'),
                SizedBox(height: 10),
                _InfoRow(
                    icon: Icons.phone_outlined,
                    title: 'Téléphone',
                    subtitle: '+212 5XX XXX XXX'),
                SizedBox(height: 10),
                _InfoRow(
                    icon: Icons.place_outlined,
                    title: 'Adresse',
                    subtitle: '123 Avenue Mohammed V, Casablanca'),
              ],
            ),
          ),
          const Divider(height: 1),
          const TabBar(
            labelColor: YColors.primary,
            unselectedLabelColor: YColors.muted,
            indicatorColor: YColors.secondary,
            tabs: [
              Tab(text: 'Promotions'),
              Tab(text: 'Avis'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: promotions.length,
                  itemBuilder: (context, index) {
                    final promo = promotions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      YColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.card_giftcard,
                                    color: YColors.secondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(promo['title']!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 4),
                                    Text(promo['description']!,
                                        style: const TextStyle(
                                            color: YColors.muted)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: YColors.secondary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                          'Valide jusqu\'au ${promo['validUntil']}',
                                          style: const TextStyle(
                                              color: YColors.secondary,
                                              fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(review['author']! as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 16, color: YColors.secondary),
                                      const SizedBox(width: 4),
                                      Text('${review['rating']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(review['comment']! as String,
                                  style: const TextStyle(color: YColors.muted)),
                              const SizedBox(height: 8),
                              Text(review['date']! as String,
                                  style: const TextStyle(
                                      color: YColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: YColors.muted),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: YColors.muted)),
          ],
        ),
      ],
    );
  }
}
