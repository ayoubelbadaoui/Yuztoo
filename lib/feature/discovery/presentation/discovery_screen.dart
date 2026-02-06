import 'package:flutter/material.dart';
import '../../../theme.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen(
      {super.key, required this.onBack, required this.onStoreSelect});

  final VoidCallback onBack;
  final VoidCallback onStoreSelect;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final categories = [
    'Tous',
    'Restaurants',
    'Cafés',
    'Santé',
    'Beauté',
    'Shopping'
  ];
  String selectedCategory = 'Tous';

  final stores = [
    {
      'name': 'Café Central',
      'category': 'Restaurant',
      'rating': 4.5,
      'distance': '0.5 km',
      'image':
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400',
      'hasPromo': true
    },
    {
      'name': 'Pharmacie El Amane',
      'category': 'Santé',
      'rating': 4.8,
      'distance': '1.2 km',
      'image':
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400',
      'hasPromo': false
    },
    {
      'name': 'Pâtisserie Délice',
      'category': 'Boulangerie',
      'rating': 4.6,
      'distance': '0.8 km',
      'image':
          'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=400',
      'hasPromo': true
    },
    {
      'name': 'Salon Beauté',
      'category': 'Beauté',
      'rating': 4.3,
      'distance': '1.5 km',
      'image':
          'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
      'hasPromo': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back)),
                const SizedBox(width: 8),
                Text('Découvrir',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
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
                  child: const Icon(Icons.filter_list, color: YColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => selectedCategory = category),
                  selectedColor: YColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : YColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
          const SizedBox(height: 12),
          const TabBar(
            labelColor: YColors.primary,
            unselectedLabelColor: YColors.muted,
            indicatorColor: YColors.secondary,
            tabs: [
              Tab(text: 'À proximité'),
              Tab(text: 'Populaires'),
              Tab(text: 'Promotions'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _StoreList(
                  stores: _filteredStores(stores),
                  onTap: widget.onStoreSelect,
                  showPromo: true,
                ),
                _StoreList(
                  stores: _filteredStores([...stores]..sort((a, b) =>
                      (b['rating'] as num).compareTo(a['rating'] as num))),
                  onTap: widget.onStoreSelect,
                ),
                _StoreList(
                  stores: _filteredStores(
                      stores.where((s) => s['hasPromo'] == true).toList()),
                  onTap: widget.onStoreSelect,
                  showPromo: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filteredStores(List<Map<String, dynamic>> list) {
    if (selectedCategory == 'Tous') return list;
    return list
        .where((store) => store['category'] == selectedCategory)
        .toList();
  }
}

class _StoreList extends StatelessWidget {
  const _StoreList(
      {required this.stores, required this.onTap, this.showPromo = false});

  final List<Map<String, dynamic>> stores;
  final VoidCallback onTap;
  final bool showPromo;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: 112,
                        height: 112,
                        child: Image.network(store['image'] as String,
                            fit: BoxFit.cover),
                      ),
                      if (showPromo && store['hasPromo'] == true)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: YColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Promo',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(store['name'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade100,
                                  border: Border.all(color: YColors.border),
                                ),
                                child: Text(store['category'] as String,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: YColors.secondary),
                              const SizedBox(width: 4),
                              Text('${store['rating']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.place,
                                  size: 14, color: YColors.muted),
                              const SizedBox(width: 4),
                              Text(store['distance'] as String,
                                  style: const TextStyle(color: YColors.muted)),
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
        );
      },
    );
  }
}
