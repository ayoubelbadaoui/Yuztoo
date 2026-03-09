import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/active_notification.dart';
import 'active_notification_card.dart';

/// Section showing the list of active notifications with a count badge
/// and an empty state fallback.
class ActiveNotificationsList extends StatelessWidget {
  const ActiveNotificationsList({
    super.key,
    required this.notifications,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ActiveNotification> notifications;
  final void Function(int index, bool value) onToggle;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row ──
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: MerchantColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Notifications actives',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifications.where((n) => n.isEnabled).length} actives',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── list or empty state ──
          if (notifications.isEmpty)
            _buildEmptyState()
          else
            ...List.generate(notifications.length, (i) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i < notifications.length - 1 ? 12 : 0),
                child: ActiveNotificationCard(
                  notification: notifications[i],
                  onToggle: (v) => onToggle(i, v),
                  onEdit: () => onEdit(i),
                  onDelete: () => onDelete(i),
                ),
              );
            }),

          const SizedBox(height: 20),
          Text(
            'Configurez vos notifications pour rester en contact avec vos clients automatiquement',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: MerchantColors.textGrey, size: 40),
          const SizedBox(height: 12),
          Text(
            'Aucune notification active',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: MerchantColors.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Créez votre première notification ci-dessus',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ],
      ),
    );
  }
}

