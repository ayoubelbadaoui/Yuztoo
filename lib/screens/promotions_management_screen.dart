import 'package:flutter/material.dart';
import '../theme.dart';

class PromotionsManagementScreen extends StatefulWidget {
  const PromotionsManagementScreen(
      {super.key, required this.onBack, required this.onCreatePromotion});

  final VoidCallback onBack;
  final VoidCallback onCreatePromotion;

  @override
  State<PromotionsManagementScreen> createState() =>
      _PromotionsManagementScreenState();
}

class _PromotionsManagementScreenState
    extends State<PromotionsManagementScreen> {
  late List<_Promotion> promotions;

  @override
  void initState() {
    super.initState();
    promotions = const [
      _Promotion(
          title: '20% de réduction',
          description: 'Sur tous les plats',
          validUntil: '31 Jan 2026',
          usedBy: 45,
          isActive: true),
      _Promotion(
          title: 'Café offert',
          description: 'Pour toute commande',
          validUntil: '15 Feb 2026',
          usedBy: 28,
          isActive: true),
      _Promotion(
          title: 'Menu complet -10%',
          description: 'Déjeuner uniquement',
          validUntil: '10 Jan 2026',
          usedBy: 12,
          isActive: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = promotions.where((p) => p.isActive).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              IconButton(
                  onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Promotions',
                      style: Theme.of(context).textTheme.titleLarge)),
              ElevatedButton.icon(
                onPressed: widget.onCreatePromotion,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Créer'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: YColors.accent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Actives', value: '$activeCount'),
              const _Stat(label: 'Utilisations', value: '85'),
              const _Stat(label: 'Clients atteints', value: '248'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: YColors.secondary.withValues(alpha: 0.1),
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(promo.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Switch(
                                        value: promo.isActive,
                                        activeThumbColor: YColors.secondary,
                                        onChanged: (val) => setState(() =>
                                            promotions[index] =
                                                promo.copyWith(isActive: val)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(promo.description,
                                      style: const TextStyle(
                                          color: YColors.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 16, color: YColors.muted),
                                const SizedBox(width: 6),
                                Text(promo.validUntil,
                                    style:
                                        const TextStyle(color: YColors.muted)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                const Icon(Icons.group_outlined,
                                    size: 16, color: YColors.muted),
                                const SizedBox(width: 6),
                                Text('${promo.usedBy} utilisations',
                                    style:
                                        const TextStyle(color: YColors.muted)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                child: const Text('Modifier'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                child: const Text('Envoyer push'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Promotion {
  const _Promotion({
    required this.title,
    required this.description,
    required this.validUntil,
    required this.usedBy,
    required this.isActive,
  });

  final String title;
  final String description;
  final String validUntil;
  final int usedBy;
  final bool isActive;

  _Promotion copyWith({bool? isActive}) => _Promotion(
        title: title,
        description: description,
        validUntil: validUntil,
        usedBy: usedBy,
        isActive: isActive ?? this.isActive,
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: YColors.muted, fontSize: 12)),
      ],
    );
  }
}
