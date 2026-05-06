import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../client_list/application/providers.dart' as crm_providers;
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant_partners/application/providers.dart' as partners_providers;
import '../../merchant_partners/domain/entities/merchant_partner.dart';
import '../../rappels/application/providers.dart' as rappels_providers;
import '../../rappels/presentation/widgets/quick_send_section.dart';

part 'merchant_notifications_hub_screen.part.dart';

/// "Vos notifications" hub — manual broadcast compose + history.
/// Auto-notifications (trigger rules) are a sub-screen accessible from the bottom entry.
class MerchantNotificationsHubScreen extends ConsumerStatefulWidget {
  const MerchantNotificationsHubScreen({
    super.key,
    this.onBack,
    this.onNavigate,
    this.isDualProfile = false,
  });

  final VoidCallback? onBack;
  final void Function(String)? onNavigate;
  final bool isDualProfile;

  @override
  ConsumerState<MerchantNotificationsHubScreen> createState() =>
      _MerchantNotificationsHubScreenState();
}

class _MerchantNotificationsHubScreenState
    extends ConsumerState<MerchantNotificationsHubScreen> {
  Future<void> _onQuickSend(
    String text,
    String audience,
    List<String> segments,
  ) async {
    final merchant =
        ref.read(merchant_providers.currentMerchantForOwnerProvider).valueOrNull;
    if (merchant == null) return;
    final useCase = ref.read(rappels_providers.sendMerchantNotificationProvider);
    final result = await useCase.call(
      merchantId: merchant.id,
      merchantName: merchant.name,
      text: text,
      audience: audience,
      segments: segments,
    );
    if (!mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'envoi", style: GoogleFonts.outfit()),
          backgroundColor: Colors.red[400],
        ),
      ),
      (sent) {
        ref.invalidate(
          rappels_providers.sentNotificationsProvider(merchant.id),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification envoyée à $sent client${sent > 1 ? 's' : ''}',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final merchant = merchantAsync.valueOrNull;
    final merchantId = merchant?.id ?? '';

    final historyAsync =
        ref.watch(rappels_providers.sentNotificationsProvider(merchantId));

    final autoNotifAsync =
        ref.watch(rappels_providers.autoNotificationsProvider(merchantId));
    final autoCount = autoNotifAsync.valueOrNull?.length ?? 0;

    final clientCount = merchantId.isEmpty
        ? 0
        : (ref
                .watch(crm_providers.merchantClientsProvider(merchantId))
                .valueOrNull
                ?.length ??
            0);

    final partners = ref
        .watch(partners_providers.merchantPartnersProvider(merchantId))
        .valueOrNull ??
        [];

    return _buildScaffold(
      context,
      merchant: merchant,
      merchantId: merchantId,
      historyAsync: historyAsync,
      autoCount: autoCount,
      clientCount: clientCount,
      partners: partners,
    );
  }
}
