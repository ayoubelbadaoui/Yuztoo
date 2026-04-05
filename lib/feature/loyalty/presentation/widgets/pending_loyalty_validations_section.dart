import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../auth/core/application/state/auth_state.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../../rappels/presentation/widgets/rappels_section_header.dart';
import '../../application/client_loyalty_providers.dart' as client_loyalty_providers;
import '../../domain/entities/loyalty_pending_client_row.dart';

/// Liste des clients avec passage(s) en attente — affiché dans Rappels si validation manuelle.
class PendingLoyaltyValidationsSection extends ConsumerStatefulWidget {
  const PendingLoyaltyValidationsSection({super.key, required this.merchant});

  final Merchant merchant;

  @override
  ConsumerState<PendingLoyaltyValidationsSection> createState() =>
      _PendingLoyaltyValidationsSectionState();
}

class _PendingLoyaltyValidationsSectionState
    extends ConsumerState<PendingLoyaltyValidationsSection> {
  String? _busyClientUid;

  LoyaltyProgramConfig get _config =>
      widget.merchant.loyaltyProgram ??
      LoyaltyProgramConfig.fallbackFromFlags(
        loyaltyEnabled: widget.merchant.loyaltyEnabled,
      );

  bool get _visible =>
      widget.merchant.loyaltyEnabled &&
      _config.programEnabled &&
      _config.passageValidation == LoyaltyPassageValidation.manual;

  static String _shortClientLabel(String uid) {
    if (uid.length <= 8) return uid;
    return '…${uid.substring(uid.length - 8)}';
  }

  Future<double?> _promptSpendAmount(BuildContext context) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: MerchantColors.navyCard,
          title: Text(
            'Montant à comptabiliser',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Montant (€)',
              labelStyle: GoogleFonts.outfit(color: MerchantColors.textLightGrey),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: MerchantColors.gold.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: MerchantColors.gold),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: GoogleFonts.outfit(color: MerchantColors.gold)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MerchantColors.gold,
                foregroundColor: MerchantColors.darkOverlay,
              ),
              onPressed: () {
                final raw = controller.text.replaceAll(',', '.').trim();
                final v = double.tryParse(raw);
                if (v != null && v > 0) {
                  Navigator.pop(ctx, v);
                }
              },
              child: Text('Valider', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return amount;
  }

  Future<void> _onValidateOne(LoyaltyPendingClientRow row) async {
    final auth = ref.read(auth_providers.authStateProvider);
    if (auth is! Authenticated) return;
    if (auth.user.id != widget.merchant.ownerUid) return;

    double? spend;
    if (_config.triggerType != LoyaltyTriggerType.visitCount) {
      if (!mounted) return;
      spend = await _promptSpendAmount(context);
      if (spend == null) return;
    }

    setState(() => _busyClientUid = row.clientUid);
    final useCase =
        ref.read(client_loyalty_providers.validatePendingLoyaltyPassageProvider);
    final result = await useCase.call(
      actingOwnerUid: auth.user.id,
      merchant: widget.merchant,
      clientUid: row.clientUid,
      declaredSpendEuros: spend,
    );
    if (!mounted) return;
    setState(() => _busyClientUid = null);

    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Passage validé pour ${_shortClientLabel(row.clientUid)}',
              style: GoogleFonts.outfit(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    final pendingAsync = ref.watch(
      client_loyalty_providers.pendingLoyaltyClientsForMerchantProvider(
        widget.merchant.id,
      ),
    );

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (List<LoyaltyPendingClientRow> rows) {
        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RappelsSectionHeader(
                icon: Icons.how_to_reg_outlined,
                title: 'Passages à valider',
                subtitle: 'fidélité — validation manuelle',
              ),
              const SizedBox(height: 12),
              Text(
                'Les clients ont enregistré un passage ; validez-le pour mettre à jour leur progression.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.5,
                  color: MerchantColors.textLightGrey,
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map((LoyaltyPendingClientRow row) {
                final busy = _busyClientUid == row.clientUid;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: MerchantColors.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MerchantColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Client ${_shortClientLabel(row.clientUid)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${row.progress.pendingPassages} passage(s) en attente',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: MerchantColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: busy ? null : () => _onValidateOne(row),
                          style: FilledButton.styleFrom(
                            backgroundColor: MerchantColors.gold,
                            foregroundColor: MerchantColors.darkOverlay,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: MerchantColors.darkOverlay,
                                  ),
                                )
                              : Text(
                                  'Valider 1',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
