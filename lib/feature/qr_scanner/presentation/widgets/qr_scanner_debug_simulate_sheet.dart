import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../auth/core/application/providers.dart';
import '../../../auth/core/application/state/auth_state.dart';
import '../../../client_home/application/providers.dart';
import '../../../merchant/application/providers.dart' as merchant_providers;
import '../../../merchant/domain/entities/merchant.dart';

/// Debug-only bottom sheet: pick a commerce and simulate a QR/NFC vitrine scan.
Future<String?> showQrScannerDebugSimulateSheet(BuildContext context) {
  assert(
    kDebugMode ||
        const bool.fromEnvironment('SHOW_SCAN_SIMULATOR', defaultValue: false),
  );
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MerchantColors.bgMain,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _QrScannerDebugSimulateSheet(),
  );
}

class _QrScannerDebugSimulateSheet extends ConsumerStatefulWidget {
  const _QrScannerDebugSimulateSheet();

  @override
  ConsumerState<_QrScannerDebugSimulateSheet> createState() =>
      _QrScannerDebugSimulateSheetState();
}

class _QrScannerDebugSimulateSheetState
    extends ConsumerState<_QrScannerDebugSimulateSheet> {
  final _merchantIdCtrl = TextEditingController();
  String? _selectedId;

  @override
  void dispose() {
    _merchantIdCtrl.dispose();
    super.dispose();
  }

  void _selectMerchant(String id) {
    setState(() {
      _selectedId = id;
      _merchantIdCtrl.text = id;
    });
  }

  void _confirm() {
    final id = _merchantIdCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Choisissez ou saisissez un ID commerce',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(clientHomeFeedProvider);
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final auth = ref.watch(authStateProvider);
    final isSignedIn = auth is Authenticated;

    final carnetMerchants = feedAsync.valueOrNull?.merchants ?? <Merchant>[];
    final ownMerchant = merchantAsync.valueOrNull;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade700),
                ),
                child: Text(
                  'DEBUG',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade200,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Simuler un scan QR',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Comme si vous aviez scanné la vitrine : ouverture du commerce '
            'et feuille « passage fidélité » (si activée).',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
              height: 1.4,
            ),
          ),
          if (!isSignedIn) ...[
            const SizedBox(height: 12),
            Text(
              'Connectez-vous en tant que client pour enregistrer un passage.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.orange.shade200,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _merchantIdCtrl,
            style: GoogleFonts.outfit(color: MerchantColors.textWhite),
            decoration: InputDecoration(
              labelText: 'ID commerce (Firestore)',
              labelStyle: GoogleFonts.outfit(color: MerchantColors.textGrey),
              hintText: 'ex. abc123…',
              hintStyle: GoogleFonts.outfit(
                color: MerchantColors.textGrey.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: MerchantColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: MerchantColors.gold.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MerchantColors.gold),
              ),
            ),
            onChanged: (v) => setState(() => _selectedId = v.trim()),
          ),
          if (ownMerchant != null) ...[
            const SizedBox(height: 16),
            Text(
              'Mon commerce (compte pro)',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            _MerchantChip(
              label: ownMerchant.displayName?.isNotEmpty == true
                  ? ownMerchant.displayName!
                  : ownMerchant.name,
              merchantId: ownMerchant.id,
              selected: _selectedId == ownMerchant.id,
              onTap: () => _selectMerchant(ownMerchant.id),
            ),
          ],
          if (carnetMerchants.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Carnet (commerces suivis)',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in carnetMerchants)
                  _MerchantChip(
                    label: m.displayName?.isNotEmpty == true
                        ? m.displayName!
                        : m.name,
                    merchantId: m.id,
                    selected: _selectedId == m.id,
                    onTap: () => _selectMerchant(m.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: Text(
                'Simuler le scan',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantChip extends StatelessWidget {
  const _MerchantChip({
    required this.label,
    required this.merchantId,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String merchantId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? MerchantColors.gold.withValues(alpha: 0.2)
          : MerchantColors.bgHeader,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? MerchantColors.gold
                  : MerchantColors.gold.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? MerchantColors.gold
                  : MerchantColors.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}
