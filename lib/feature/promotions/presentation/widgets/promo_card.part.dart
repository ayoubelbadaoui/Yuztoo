part of 'promo_card.dart';

extension _PromoCardUi on PromoCard {
  String _fmt(DateTime d, {String prefix = ''}) =>
      '$prefix${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  bool get _isExpired => !promo.dateTo.isAfter(DateTime.now());
  bool get _isLive => promo.isOnline && !_isExpired;

  Color get _borderColor {
    if (_isExpired) return MerchantColors.textGrey.withValues(alpha: 0.25);
    if (!promo.isOnline) return MerchantColors.gold.withValues(alpha: 0.2);
    return MerchantColors.gold
        .withValues(alpha: MerchantColors.goldBorderStronger);
  }

  Widget _datePill(String text, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: muted
            ? MerchantColors.textGrey.withValues(alpha: 0.15)
            : MerchantColors.gold,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: muted ? MerchantColors.textGrey : MerchantColors.darkOverlay,
        ),
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _isExpired ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: MerchantColors.bgHeader,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusBanner(),
            _buildValidityRow(),
            _buildClientsRow(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// Thin coloured banner below the header showing online/offline/expired state.
  Widget _buildStatusBanner() {
    if (_isLive) return const SizedBox.shrink();
    final label = _isExpired ? 'Expirée' : 'Hors ligne';
    final color = _isExpired
        ? MerchantColors.textGrey.withValues(alpha: 0.15)
        : MerchantColors.gold.withValues(alpha: 0.08);
    final textColor =
        _isExpired ? MerchantColors.textGrey : MerchantColors.gold;
    final icon =
        _isExpired ? Icons.schedule_rounded : Icons.visibility_off_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isExpired ? null : onPickImage,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: MerchantColors.bgHeader,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: promo.imagePath != null
                  ? Image.file(
                      File(promo.imagePath!),
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                    )
                  : (promo.imageUrl != null && promo.imageUrl!.isNotEmpty)
                      ? Image.network(
                          promo.imageUrl!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        )
                      : Center(
                          child: Icon(
                            _isExpired
                                ? Icons.image_outlined
                                : Icons.add_photo_alternate_outlined,
                            color: _isExpired
                                ? MerchantColors.textGrey
                                : MerchantColors.gold,
                            size: 24,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: MerchantColors.bgHeader,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    promo.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isExpired
                          ? MerchantColors.textGrey
                          : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    promo.subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: MerchantColors.textGrey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidityRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: MerchantColors.gold.withValues(alpha: 0.2), width: 1),
          bottom: BorderSide(
              color: MerchantColors.gold.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Validité',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _isExpired ? MerchantColors.textGrey : Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          _datePill(_fmt(promo.dateFrom, prefix: 'Du '), muted: _isExpired),
          const SizedBox(width: 8),
          _datePill(_fmt(promo.dateTo, prefix: 'au '), muted: _isExpired),
          const Spacer(),
          // View count badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 12,
                color: MerchantColors.gold.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                '${promo.viewCount}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.gold.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsRow() {
    final typeLabel = switch (promo.selectedClientType) {
      ClientType.gratuit => 'Mes clients',
      ClientType.premium => 'Ciblés',
      ClientType.payant => 'Yuztoo',
    };
    final pillLabel = switch (promo.selectedClientType) {
      ClientType.gratuit => 'Tous mes clients',
      ClientType.premium => 'Ciblées',
      ClientType.payant => 'Clients Yuztoo',
    };

    const segmentLabels = {
      'vip': 'VIP',
      'soutien': 'Soutien',
      'habitue': 'Habitué',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Clients',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isExpired ? MerchantColors.textGrey : Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                typeLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _isExpired
                      ? MerchantColors.textGrey
                      : MerchantColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isExpired
                      ? MerchantColors.textGrey.withValues(alpha: 0.12)
                      : MerchantColors.gold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  pillLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _isExpired
                        ? MerchantColors.textGrey
                        : MerchantColors.darkOverlay,
                  ),
                ),
              ),
              // Zone badge for payant
              if (promo.diffusionZone != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: MerchantColors.navyCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: MerchantColors.gold),
                      const SizedBox(width: 3),
                      Text(
                        promo.diffusionZone!.label,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // Segment chips for premium
          if (promo.selectedClientType == ClientType.premium &&
              promo.targetSegments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: promo.targetSegments.map((key) {
                final label = segmentLabels[key] ?? key;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Toggle with proper 44px touch target
          GestureDetector(
            onTap: _isExpired ? null : () => onToggle(!promo.isOnline),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggle(),
                  const SizedBox(width: 8),
                  Text(
                    promo.isOnline ? 'En ligne' : 'Hors ligne',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _isExpired
                          ? MerchantColors.textGrey
                          : (promo.isOnline
                              ? MerchantColors.gold
                              : MerchantColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Delete with 44px touch target
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(
                Icons.delete_outline_rounded,
                color: _isExpired
                    ? MerchantColors.textGrey
                    : MerchantColors.gold,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    if (_isExpired) {
      return Container(
        width: 40,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF2A3040),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.textGrey.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 40,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: promo.isOnline
            ? MerchantColors.gold
            : const Color(0xFF444444),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        alignment:
            promo.isOnline ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
