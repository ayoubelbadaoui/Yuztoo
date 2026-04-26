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
    );
    ref.invalidate(partners_providers.merchantPartnersProvider(merchantId));
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
