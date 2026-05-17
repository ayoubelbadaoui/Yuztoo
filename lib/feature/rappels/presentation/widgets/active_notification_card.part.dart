part of 'active_notification_card.dart';

extension _ActiveNotificationCardUi on ActiveNotificationCard {
  Widget _buildActiveNotificationCard(BuildContext context) {
    final isOn = notification.isEnabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn
              ? MerchantColors.gold.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => onToggle(!isOn),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isOn
                            ? MerchantColors.gold
                            : const Color(0xFF3A4A5C),
                        border: isOn
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1),
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            left: isOn ? 22 : 2,
                            top: 2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isOn ? Colors.white : MerchantColors.textGrey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: _infoPill(
                                  Icons.bolt_rounded, notification.trigger, isOn),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: _infoPill(Icons.people_outline_rounded,
                                  notification.audience, isOn),
                            ),
                          ],
                        ),
                        if (notification.targetSegments.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: notification.targetSegments
                                .map((s) => _segmentTag(s, isOn))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 6),
                        _cloudStatusBadge(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _actionButton(
                icon: Icons.edit_outlined,
                label: 'Modifier',
                color: MerchantColors.gold,
                onTap: onEdit,
              ),
              const SizedBox(width: 4),
              _actionButton(
                icon: Icons.science_outlined,
                label: 'Tester',
                color: const Color(0xFF64B5F6),
                onTap: onTest ?? () {},
              ),
              const Spacer(),
              // Delivery stats — show when sent at least once.
              if (notification.sentCount > 0) ...[
                const Icon(
                  Icons.send_rounded,
                  size: 11,
                  color: MerchantColors.textGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  _deliveryLabel(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: MerchantColors.textGrey,
                  ),
                ),
                const Spacer(),
              ],
              _actionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Supprimer',
                color: const Color(0xFFE57373),
                onTap: onDelete,
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _cloudStatusBadge() {
    final isWired = AutoNotificationTriggers.isWiredInCloud(notification.trigger);
    final color = isWired ? const Color(0xFF64B5F6) : const Color(0xFFFFB74D);
    final icon = isWired ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;
    final label = isWired ? 'Exécuté automatiquement par le service cloud' : 'Déclencheur en cours d\'intégration';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _segmentTag(String key, bool isOn) {
    const labels = {
      'vip': 'VIP',
      'habitue': 'Habitué',
      'nouveau': 'Nouveau',
      'abonne': 'Abonné',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOn
            ? MerchantColors.gold.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOn
              ? MerchantColors.gold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Text(
        labels[key] ?? key,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isOn ? MerchantColors.gold : MerchantColors.textLightGrey,
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label, bool isOn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOn
            ? MerchantColors.gold.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color:
                  isOn ? MerchantColors.gold : MerchantColors.textLightGrey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isOn
                    ? MerchantColors.gold
                    : MerchantColors.textLightGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _deliveryLabel() {
    final count = notification.sentCount;
    final lastSent = notification.lastSentAt;
    final countStr = '$count envoi${count > 1 ? 's' : ''}';
    if (lastSent == null) return countStr;
    final diff = DateTime.now().difference(lastSent);
    final String timeStr;
    if (diff.inMinutes < 60) {
      timeStr = 'il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      timeStr = 'il y a ${diff.inHours} h';
    } else {
      timeStr = 'il y a ${diff.inDays} j';
    }
    return '$countStr · $timeStr';
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
