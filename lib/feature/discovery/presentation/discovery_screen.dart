import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../client_home/application/providers.dart' as client_home_providers;
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../../merchant/domain/entities/merchant.dart';

part 'discovery_screen.part.dart';


/// Découvrir / Recommandations – design.md layout, MerchantColors, real data from Firestore.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({
    super.key,
    required this.onBack,
    required this.onNotifications,
    required this.onStoreSelect,
  });

  static String get path => '/discovery';

  final VoidCallback onBack;
  final VoidCallback onNotifications;
  /// Called with merchant id when user taps a business (featured or grid).
  final ValueChanged<String> onStoreSelect;

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String v) {
    setState(() => _searchQuery = v);
  }

  @override
  Widget build(BuildContext context) {
    final merchantsAsync = ref.watch(discoveryMerchantsProvider);
    final viewedIdsAsync =
        ref.watch(client_home_providers.viewedMerchantIdsForCurrentUserProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
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
              child: merchantsAsync.when(
                data: (merchants) =>
                    _buildContent(context, merchants, viewedIdsAsync.valueOrNull ?? const <String>{}),
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
                error: (_, __) => _buildContent(context, [], const <String>{}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
