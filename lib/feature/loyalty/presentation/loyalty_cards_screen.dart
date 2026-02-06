import 'package:flutter/material.dart';
import '../../../theme.dart';

class LoyaltyCardsScreen extends StatelessWidget {
  const LoyaltyCardsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  static final cards = [
    {
      'store': 'Café Central',
      'currentPoints': 120,
      'nextReward': 150,
      'rewardText': 'Café offert',
      'totalVisits': 24,
      'image': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400'
    },
    {
      'store': 'Pharmacie El Amane',
      'currentPoints': 80,
      'nextReward': 100,
      'rewardText': '10% de réduction',
      'totalVisits': 16,
      'image':
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400'
    },
    {
      'store': 'Pâtisserie Délice',
      'currentPoints': 45,
      'nextReward': 50,
      'rewardText': 'Pâtisserie offerte',
      'totalVisits': 9,
      'image':
          'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=400'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                    onPressed: onBack, icon: const Icon(Icons.arrow_back)),
                const SizedBox(width: 8),
                Text('Mes cartes de fidélité',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: YColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Points totaux',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('245',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: YColors.secondary,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('+15',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Stat(label: 'Commerces', value: '${cards.length}'),
                    const SizedBox(width: 24),
                    const _Stat(label: 'Récompenses', value: '3'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: cards
                  .map((card) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _LoyaltyCard(card: card),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({required this.card});

  final Map<String, dynamic> card;

  @override
  Widget build(BuildContext context) {
    final current = card['currentPoints'] as int;
    final next = card['nextReward'] as int;
    final progress = current / next;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [YColors.primary, Color(0xFF2E3643)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star,
                        color: YColors.secondary, size: 26),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card['store'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$current',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        const Text('points',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prochaine récompense',
                        style: TextStyle(color: YColors.muted)),
                    Text('${next - current} points',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: YColors.accent,
                    color: YColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.card_giftcard,
                            size: 18, color: YColors.secondary),
                        const SizedBox(width: 6),
                        Text(card['rewardText'] as String,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade100,
                        border: Border.all(color: YColors.border),
                      ),
                      child: Text('${card['totalVisits']} visites',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
