import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import 'widgets/client_info_box.dart';
import 'widgets/client_item_card.dart';
import 'widgets/client_qr_box.dart';
import 'widgets/client_search_bar.dart';

/// "Vos clients" screen – merchant client list.
///
/// Thin orchestrator composing:
///  • [ClientSearchBar] – Mode Pro badge + search + filter
///  • [ClientItemCard] – individual client rows (reused per client)
///  • [ClientInfoBox] – gold-bordered info text
///  • [ClientQrBox] – QR code scan card
class ClientListScreen extends StatelessWidget {
  const ClientListScreen({
    super.key,
    required this.onBack,
    required this.onClientSelect,
  });

  static String get path => '/merchant-clients';

  final VoidCallback onBack;
  final VoidCallback onClientSelect;

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: Column(
                  children: [
                    const ClientSearchBar(),
                    // Client list will be loaded from Firestore/backend when available
                    const ClientInfoBox(),
                    const ClientQrBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Text(
              'Vos clients',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
