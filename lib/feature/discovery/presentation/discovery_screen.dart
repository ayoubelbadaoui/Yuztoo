import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../../../core/shared/widgets/snackbar.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({
    super.key,
    required this.onBack,
    required this.onStoreSelect,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onStoreSelect; // Changed to pass merchantId

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  // Map category IDs to display names
  static const Map<String, String> _categoryIdToName = {
    'restaurant': 'Restaurants',
    'retail': 'Shopping',
    'beauty': 'Beauté',
    'fitness': 'Sport',
    'services': 'Services',
    'other': 'Autre',
  };

  final categories = [
    'Tous',
    'Restaurants',
    'Shopping',
    'Beauté',
    'Sport',
    'Services',
    'Autre',
  ];
  String selectedCategory = 'Tous';
  List<Merchant> _merchants = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // FIX HIGH 7: Limit applied in repository (100 merchants max)
  // Full pagination would require repository interface changes

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  Future<void> _loadMerchants({bool isRetry = false}) async {
    if (!isRetry) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    // FIX HIGH 8: Retry mechanism for failed operations
    final getMerchants = ref.read(merchant_providers.getMerchantsProvider);
    
    try {
      final result = await getMerchants.call();

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erreur lors du chargement des commerces';
            });
            
            // FIX HIGH 10: Better error recovery - show retry option
            showErrorSnackbar(
              context,
              'Impossible de charger les commerces. Appuyez pour réessayer.',
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Réessayer',
                onPressed: () => _loadMerchants(isRetry: true),
              ),
            );
          }
        },
        (merchants) {
          if (mounted) {
            setState(() {
              _merchants = merchants;
              _isLoading = false;
              _errorMessage = null;
            });
          }
        },
      );
    } catch (e) {
      // FIX HIGH 10: Handle unexpected errors gracefully
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur inattendue';
        });
        showErrorSnackbar(
          context,
          'Erreur inattendue. Appuyez pour réessayer.',
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: () => _loadMerchants(isRetry: true),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _convertMerchantsToStores(List<Merchant> merchants) {
    return merchants.map((merchant) {
      // Get first category ID or default to 'other'
      final categoryId = merchant.categories?.isNotEmpty == true
          ? merchant.categories!.first
          : 'other';
      
      // Map category ID to display name
      final categoryName = _categoryIdToName[categoryId] ?? 'Autre';
      
      return {
        'id': merchant.id,
        'name': merchant.name,
        'category': categoryName,
        'categoryId': categoryId, // Store ID for filtering
        'rating': 4.5, // Default rating (can be added to Merchant entity later)
        'distance': merchant.city, // Using city for now (distance calculation can be added later)
        'image': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400', // Default image
        'hasPromo': false, // Can be added to Merchant entity later
        'merchant': merchant, // Store full merchant object for navigation
      };
    }).toList();
  }

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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMerchants,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _merchants.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.store_outlined, size: 64, color: YColors.muted),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aucun commerce disponible',
                                  style: TextStyle(color: YColors.muted),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadMerchants,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Actualiser'),
                                ),
                              ],
                            ),
                          )
                        : TabBarView(
                            children: [
                              RefreshIndicator(
                                onRefresh: _loadMerchants,
                                child: _StoreList(
                                  stores: _filteredStores(
                                      _convertMerchantsToStores(_merchants)),
                                  onTap: (merchantId) => widget.onStoreSelect(merchantId),
                                  showPromo: true,
                                ),
                              ),
                              RefreshIndicator(
                                onRefresh: _loadMerchants,
                                child: _StoreList(
                                  stores: _filteredStores(
                                      _convertMerchantsToStores([..._merchants]
                                        ..sort((a, b) {
                                          // Sort by name for now (rating can be added later)
                                          return a.name.compareTo(b.name);
                                        }))),
                                  onTap: (merchantId) => widget.onStoreSelect(merchantId),
                                ),
                              ),
                              RefreshIndicator(
                                onRefresh: _loadMerchants,
                                child: _StoreList(
                                  stores: _filteredStores(
                                      _convertMerchantsToStores(_merchants)
                                          .where((s) => s['hasPromo'] == true)
                                          .toList()),
                                  onTap: (merchantId) => widget.onStoreSelect(merchantId),
                                  showPromo: true,
                                ),
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
    // Filter by category display name
    return list
        .where((store) => store['category'] == selectedCategory)
        .toList();
  }
}

class _StoreList extends StatelessWidget {
  const _StoreList({
    required this.stores,
    required this.onTap,
    this.showPromo = false,
  });

  final List<Map<String, dynamic>> stores;
  final ValueChanged<String> onTap; // Changed to pass merchantId
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
            onTap: () => onTap(store['id'] as String),
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
