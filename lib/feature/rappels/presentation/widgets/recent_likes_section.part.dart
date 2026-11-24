part of 'recent_likes_section.dart';

extension _RecentLikesSectionUi on _RecentLikesSectionState {
  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<MerchantLikeAlert>> likesAsync,
  ) {
    return likesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (List<MerchantLikeAlert> rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: RappelsSectionHeader(
                      icon: Icons.favorite_border_rounded,
                      title: 'Nouveaux likes',
                      subtitle: 'Qui a aimé vos promos et actualités',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A7A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF5A7A).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '${rows.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF5A7A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...rows.map((MerchantLikeAlert row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: MerchantColors.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF5A7A).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color(0xFFFF5A7A).withValues(alpha: 0.12),
                          ),
                          child: Center(
                            child: Text(
                              row.displayLabel.isNotEmpty
                                  ? row.displayLabel[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF5A7A),
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
                              const SizedBox(height: 2),
                              Text(
                                row.actionLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: MerchantColors.textLightGrey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(row.createdAt),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: MerchantColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          row.source == MerchantLikeSource.promotion
                              ? Icons.local_offer_outlined
                              : Icons.photo_outlined,
                          size: 18,
                          color: const Color(0xFFFF5A7A).withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
                    : _MarkSeenButton(
                        label: rows.length == 1
                            ? 'Marquer comme vu'
                            : 'Tout marquer comme vu (${rows.length})',
                        onTap: _onMarkAllSeen,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} j';
  }
}

class _MarkSeenButton extends StatelessWidget {
  const _MarkSeenButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
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
