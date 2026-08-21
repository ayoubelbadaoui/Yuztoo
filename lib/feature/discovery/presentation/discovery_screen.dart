import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../client_home/application/providers.dart' as client_home_providers;
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/yuztoo_gradient_title.dart';
import '../../../core/shared/widgets/yuztoo_pull_refresh.dart';
import '../application/providers.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant_partners/application/providers.dart' as partners_providers;

part 'discovery_screen.part.dart';


/// Découvrir / Recommandations – design.md layout, MerchantColors, real data from Firestore.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({
    super.key,
    required this.onBack,
    required this.onNotifications,
    required this.onStoreSelect,
    this.isDualProfile = false,
  });

  static String get path => '/discovery';

  final VoidCallback onBack;
  final VoidCallback onNotifications;
  /// Called with merchant id when user taps a business (featured or grid).
  final ValueChanged<String> onStoreSelect;
  /// True when the user also has a merchant account.
  final bool isDualProfile;

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchLoading = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Fresh catalog when opening Découvrir (new merchants / city updates).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(discoveryCityMerchantsProvider);
      ref.invalidate(discoveryRecommendedMerchantsProvider);
      ref.invalidate(discoveryFollowedMerchantsProvider);
      ref.invalidate(discoveryMerchantsProvider);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String v) {
    _searchDebounce?.cancel();
    setState(() => _searchQuery = v);
    if (v.trim().length >= 2) {
      setState(() => _searchLoading = true);
      _searchDebounce = Timer(
        const Duration(milliseconds: 350),
        () => _performSearch(v.trim()),
      );
    } else {
      setState(() { _searchResults = []; _searchLoading = false; });
    }
  }

  Future<void> _performSearch(String q) async {
    try {
      final results = await partners_providers.searchMerchantsProvider(q);
      if (mounted && _searchQuery.trim() == q) {
        setState(() => _searchResults = results);
      }
    } catch (_) {
      if (mounted && _searchQuery.trim() == q) {
        setState(() => _searchResults = []);
      }
    } finally {
      if (mounted && _searchQuery.trim() == q) {
        setState(() => _searchLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantsAsync = ref.watch(discoveryMerchantsProvider);
    final viewedIdsAsync =
        ref.watch(client_home_providers.viewedMerchantIdsForCurrentUserProvider);
    final followedIdsAsync =
        ref.watch(client_home_providers.followedMerchantIdsForCurrentUserProvider);
    final isSearching = _searchQuery.trim().length >= 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: isSearching
                  ? _buildSearchResults(
                      context,
                      followedIdsAsync.valueOrNull?.toSet() ?? const <String>{},
                    )
                  : merchantsAsync.when(
                      data: (merchants) => _buildContent(
                        context,
                        merchants,
                        viewedIdsAsync.valueOrNull ?? const <String>{},
                        followedIdsAsync.valueOrNull?.toSet() ??
                            const <String>{},
                      ),
                      loading: () => const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: MerchantColors.gold,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (_, __) => _buildContent(
                        context,
                        [],
                        const <String>{},
                        const <String>{},
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
