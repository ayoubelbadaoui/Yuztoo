import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../loyalty/application/client_loyalty_providers.dart'
    show merchantClientLoyaltyProgressProvider;
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../promotions/application/providers.dart'
    show merchantTotalPromoViewsProvider;
import '../application/providers.dart' as crm_providers;
import '../domain/entities/merchant_client_row.dart';
import 'widgets/client_item_card.dart';

part 'client_list_screen.part.dart';

// ── DUMMY DATA — remove this block when real Firestore clients are available ──
final _kDummyClients = <MerchantClientRow>[
  MerchantClientRow(
    clientUid: 'dummy_1',
    displayName: 'Sophie Martin',
    city: 'Paris',
    followedAt: DateTime.now().subtract(const Duration(days: 3)),
    heartLevel: 3,
  ),
  MerchantClientRow(
    clientUid: 'dummy_2',
    displayName: 'Karim Benali',
    city: 'Lyon',
    followedAt: DateTime.now().subtract(const Duration(days: 45)),
    heartLevel: 2,
  ),
  MerchantClientRow(
    clientUid: 'dummy_3',
    displayName: 'Lucie Fontaine',
    city: 'Marseille',
    followedAt: DateTime.now().subtract(const Duration(days: 90)),
    heartLevel: 1,
  ),
  MerchantClientRow(
    clientUid: 'dummy_4',
    displayName: 'Amine Touati',
    city: 'Paris',
    followedAt: DateTime.now().subtract(const Duration(days: 5)),
    heartLevel: 1,
  ),
  MerchantClientRow(
    clientUid: 'dummy_5',
    displayName: 'Nadia Rouill',
    city: 'Bordeaux',
    followedAt: DateTime.now().subtract(const Duration(days: 120)),
    heartLevel: 3,
  ),
  MerchantClientRow(
    clientUid: 'dummy_6',
    displayName: 'Thomas Girard',
    city: 'Nantes',
    followedAt: DateTime.now().subtract(const Duration(days: 60)),
    heartLevel: 2,
  ),
];

// DUMMY — total promo views shown in stats panel.
// Replace with: sum of view_count across all merchant promotions from Firestore.
const int _kDummyPromoViews = 47;
// ─────────────────────────────────────────────────────────────────────────────

enum _Section { list, apercu }

enum _ApercuPeriod {
  sevenDays,
  thirtyDays,
  all;

  String get label {
    switch (this) {
      case _ApercuPeriod.sevenDays:
        return '7 jours';
      case _ApercuPeriod.thirtyDays:
        return '30 jours';
      case _ApercuPeriod.all:
        return 'Tout';
    }
  }

  /// Returns null for "all" (no date cutoff), or a cutoff DateTime.
  DateTime? get cutoff {
    switch (this) {
      case _ApercuPeriod.sevenDays:
        return DateTime.now().subtract(const Duration(days: 7));
      case _ApercuPeriod.thirtyDays:
        return DateTime.now().subtract(const Duration(days: 30));
      case _ApercuPeriod.all:
        return null;
    }
  }
}

/// "Vos clients" screen — live Firestore CRM list.
class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({
    super.key,
    required this.onBack,
    required this.onClientSelect,
  });

  static String get path => '/merchant-clients';

  final VoidCallback onBack;
  final VoidCallback onClientSelect;

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  ClientSegment? _segmentFilter;
  String _searchQuery = '';
  _Section _section = _Section.list;
  _ApercuPeriod _apercuPeriod = _ApercuPeriod.thirtyDays;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _searchQuery) {
        setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MerchantClientRow> _applyFilters(List<MerchantClientRow> all) {
    var result = all;
    if (_segmentFilter != null) {
      result = result.where((c) => c.segment == _segmentFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((c) =>
              c.displayLabel.toLowerCase().contains(_searchQuery) ||
              (c.city?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    }
    return result;
  }

  void clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchQuery = '');
  }

  void setSegmentFilter(ClientSegment? seg) =>
      setState(() => _segmentFilter = seg);

  void setSection(_Section s) => setState(() => _section = s);

  void setApercuPeriod(_ApercuPeriod p) =>
      setState(() => _apercuPeriod = p);

  @override
  Widget build(BuildContext context) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final merchantId = merchantAsync.valueOrNull?.id ?? '';
    final clientsAsync =
        ref.watch(crm_providers.merchantClientsProvider(merchantId));

    return _buildScaffold(context, clientsAsync, merchantId);
  }

  void _showClientDetail(
      BuildContext context, MerchantClientRow client, String merchantId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _ClientDetailSheet(client: client, merchantId: merchantId),
    );
  }
}
