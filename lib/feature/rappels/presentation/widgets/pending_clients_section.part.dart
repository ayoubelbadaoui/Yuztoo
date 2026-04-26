part of 'pending_clients_section.dart';

// ── DUMMY: remove the 5 lines below before shipping ───────────────────────────
const _kDummyPendingClients = [
  PendingClientRow(clientUid: 'dummy_1', displayName: 'Marie Dupont'),
  PendingClientRow(clientUid: 'dummy_2', displayName: 'Lucas Martin'),
  PendingClientRow(clientUid: 'dummy_3', displayName: 'Sophie Bernard'),
];
// ─────────────────────────────────────────────────────────────────────────────

extension _PendingClientsSectionUi on _PendingClientsSectionState {
  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<PendingClientRow>> pendingAsync,
  ) {
    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (List<PendingClientRow> rows) {
        // Use dummy data when real list is empty and dummy mode is ON.
        final display = (widget.showDummyWhenEmpty && rows.isEmpty)
            ? _kDummyPendingClients
            : rows;
        if (display.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with count badge
              Row(
                children: [
                  const Expanded(
                    child: RappelsSectionHeader(
                      icon: Icons.person_add_outlined,
                      title: 'Nouveaux clients',
                      subtitle: 'à acquitter — validation manuelle',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MerchantColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MerchantColors.gold
                            .withValues(alpha: MerchantColors.goldBorderAlpha),
                      ),
                    ),
                    child: Text(
                      '${display.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ces clients viennent de vous suivre. Acquittez-les pour les ajouter à votre base.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.5,
                  color: MerchantColors.textLightGrey,
                ),
              ),
              const SizedBox(height: 12),

              // Client cards
              ...display.map((PendingClientRow row) {
                final busy = _busy.contains(row.clientUid) || _busyAll;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: MerchantColors.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MerchantColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MerchantColors.gold.withValues(alpha: 0.12),
                          ),
                          child: Center(
                            child: Text(
                              row.displayLabel.isNotEmpty
                                  ? row.displayLabel[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: MerchantColors.gold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.displayLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (row.followedAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(row.followedAt!),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: MerchantColors.textGrey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        busy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: MerchantColors.gold,
                                ),
                              )
                            : _GradientButton(
                                label: 'Acquitter',
                                onTap: () => _onAcknowledge(row),
                              ),
                      ],
                    ),
                  ),
                );
              }),

              // Tout acquitter bulk button
              if (display.length > 1) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: _busyAll
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MerchantColors.gold,
                              ),
                            ),
                          ),
                        )
                      : _GradientButton(
                          label: 'Tout acquitter (${display.length})',
                          onTap: () => _onAcknowledgeAll(display),
                          fullWidth: true,
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} j';
  }
}

// ── Shared gradient button ────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: fullWidth ? 0 : 16,
          vertical: fullWidth ? 12 : 8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [MerchantColors.gold, Color(0xFFD4AF37)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: MerchantColors.gold.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MerchantColors.bgHeader,
            ),
          ),
        ),
      ),
    );
  }
}
