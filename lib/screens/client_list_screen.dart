import 'package:flutter/material.dart';
import '../theme.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen(
      {super.key, required this.onBack, required this.onClientSelect});

  final VoidCallback onBack;
  final VoidCallback onClientSelect;

  static const List<ClientData> _clients = [
    ClientData(
        name: 'Mohammed A.',
        points: 245,
        visits: 38,
        lastVisit: '2 Jan 2026',
        trend: Trend.up),
    ClientData(
        name: 'Fatima Z.',
        points: 180,
        visits: 24,
        lastVisit: '2 Jan 2026',
        trend: Trend.up),
    ClientData(
        name: 'Ahmed K.',
        points: 156,
        visits: 31,
        lastVisit: '1 Jan 2026',
        trend: Trend.stable),
    ClientData(
        name: 'Sarah M.',
        points: 142,
        visits: 19,
        lastVisit: '30 Dec 2025',
        trend: Trend.up),
    ClientData(
        name: 'Youssef B.',
        points: 98,
        visits: 12,
        lastVisit: '28 Dec 2025',
        trend: Trend.down),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text('Mes clients',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: YColors.primary,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Total', value: '248'),
              _Stat(label: 'Actifs', value: '156'),
              _Stat(label: 'Nouveaux', value: '12'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un client...',
                        prefixIcon: Icon(Icons.search, color: YColors.muted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero),
                    child:
                        const Icon(Icons.filter_list, color: YColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _clients.length,
                itemBuilder: (context, index) {
                  final client = _clients[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onClientSelect,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: const BoxDecoration(
                                            color: YColors.primary,
                                            shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text(client.name.substring(0, 1),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(client.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text('${client.visits} visites',
                                                  style: const TextStyle(
                                                      color: YColors.muted)),
                                              if (client.trend == Trend.up)
                                                const Icon(Icons.trending_up,
                                                    size: 16,
                                                    color: Colors.green),
                                              if (client.trend == Trend.down)
                                                const Icon(Icons.trending_down,
                                                    size: 16,
                                                    color: Colors.red),
                                            ],
                                          ),
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
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 14, color: YColors.secondary),
                                        const SizedBox(width: 4),
                                        Text('${client.points}',
                                            style: const TextStyle(
                                                color: YColors.secondary,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Dernière visite',
                                      style: TextStyle(color: YColors.muted)),
                                  Text(client.lastVisit,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

enum Trend { up, down, stable }

class ClientData {
  final String name;
  final int points;
  final int visits;
  final String lastVisit;
  final Trend trend;

  const ClientData({
    required this.name,
    required this.points,
    required this.visits,
    required this.lastVisit,
    required this.trend,
  });
}
