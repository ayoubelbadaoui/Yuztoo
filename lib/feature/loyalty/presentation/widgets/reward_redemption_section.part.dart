part of 'reward_redemption_section.dart';

extension _RewardRedemptionSectionUi on _RewardRedemptionSectionState {
  Widget _buildRewardBody(
    BuildContext context,
    AsyncValue<List<LoyaltyPendingClientRow>> rewardAsync,
  ) {
    return rewardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (List<LoyaltyPendingClientRow> rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RappelsSectionHeader(
                icon: Icons.card_giftcard_rounded,
                title: 'Récompenses à remettre',
                subtitle: 'bons disponibles pour vos clients',
              ),
              const SizedBox(height: 8),
              Text(
                'Ces clients ont atteint le seuil de fidélité. Remettez-leur leur bon, puis appuyez sur "Donner le bon" pour démarrer un nouveau cycle.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.5,
                  color: MerchantColors.textLightGrey,
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map((LoyaltyPendingClientRow row) {
                final busy = _busyClientUid == row.clientUid;
                final passagesLabel = _isSpendBased
                    ? '${row.progress.cumulativeSpendEuros.toStringAsFixed(0)} € cumulés'
                    : '${row.progress.validatedPassages} passages validés';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: MerchantColors.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MerchantColors.gold,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MerchantColors.gold.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: MerchantColors.gold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: MerchantColors.gold,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Client ${_RewardRedemptionSectionState._shortLabel(row.clientUid)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                passagesLabel,
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
                          onPressed: busy ? null : () => _onMarkUsed(row),
                          style: FilledButton.styleFrom(
                            backgroundColor: MerchantColors.gold,
                            foregroundColor: MerchantColors.darkOverlay,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
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
                                  'Donner le bon',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
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
