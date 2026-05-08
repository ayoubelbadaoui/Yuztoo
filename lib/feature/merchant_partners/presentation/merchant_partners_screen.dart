import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../application/providers.dart' as partners_providers;
import '../domain/entities/merchant_partner.dart';

part 'merchant_partners_screen.part.dart';

class MerchantPartnersScreen extends ConsumerStatefulWidget {
  const MerchantPartnersScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<MerchantPartnersScreen> createState() =>
      _MerchantPartnersScreenState();
}

class _MerchantPartnersScreenState
    extends ConsumerState<MerchantPartnersScreen> {
  bool _isRemoving = false;

  /// Active filter on the LIST view. null = "Tous"; otherwise 'b2b' or
  /// 'b2c'. Persisted only in memory — choosing a filter is a transient
  /// browse action, not a saved preference.
  String? _typeFilter;

  Future<void> _removePartner(String merchantId, String partnerId) async {
    if (_isRemoving) return;
    setState(() => _isRemoving = true);
    try {
      final repo = ref.read(partners_providers.merchantPartnerRepositoryProvider);
      await repo.removePartner(
          merchantId: merchantId, partnerId: partnerId);
      ref.invalidate(partners_providers.merchantPartnersProvider(merchantId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression',
                style: GoogleFonts.outfit()),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  Future<void> _invitePartner(
      String merchantId, MerchantPartner? selected) async {
    if (selected == null) return;
    final repo = ref.read(partners_providers.merchantPartnerRepositoryProvider);
    await repo.addPartner(
      merchantId: merchantId,
      partnerMerchantId: selected.partnerMerchantId,
      partnerName: selected.partnerName,
      partnerLogoUrl: selected.partnerLogoUrl,
      partnerCity: selected.partnerCity,
      partnerMerchantType: selected.partnerMerchantType,
    );
    ref.invalidate(partners_providers.merchantPartnersProvider(merchantId));
  }

  void _setTypeFilter(String? type) {
    setState(() => _typeFilter = type);
  }

  /// Applies the in-memory `_typeFilter` to the live partner list.
  /// Partners issued before the merchant_type field existed have a null
  /// type and are bucketed under "Tous" only — keeping them findable
  /// even when an active filter is set would mix unverified entries
  /// into a filtered view, defeating the filter's purpose.
  List<MerchantPartner> _applyTypeFilter(List<MerchantPartner> partners) {
    final f = _typeFilter;
    if (f == null) return partners;
    return partners.where((p) => p.partnerMerchantType == f).toList();
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final merchantId = merchantAsync.valueOrNull?.id ?? '';
    final partnersAsync =
        ref.watch(partners_providers.merchantPartnersProvider(merchantId));

    return _buildScaffold(context, merchantId, partnersAsync);
  }
}
