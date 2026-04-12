part of 'pending_loyalty_validations_section.dart';

extension _PendingLoyaltyValidationsSectionUi
    on _PendingLoyaltyValidationsSectionState {
  Widget _buildSpendPromptDialog(
    BuildContext ctx,
    TextEditingController controller,
  ) {
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
            borderSide:
                BorderSide(color: MerchantColors.gold.withValues(alpha: 0.5)),
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
          child:
              Text('Annuler', style: GoogleFonts.outfit(color: MerchantColors.gold)),
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
          child: Text('Valider',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildPendingLoyaltyBody(
    BuildContext context,
    AsyncValue<List<LoyaltyPendingClientRow>> pendingAsync,
  ) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                'Client ${_PendingLoyaltyValidationsSectionState._shortClientLabel(row.clientUid)}',
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
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
