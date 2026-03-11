import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Tappable card on the Rappels screen that navigates to the
/// Notifications automatiques sub-page.
class NotificationsAutoEntry extends StatelessWidget {
  const NotificationsAutoEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderStronger),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MerchantColors.gold, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.notifications_active_outlined,
                      color: MerchantColors.gold, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications automatiques',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configurez vos notifications clients',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: MerchantColors.gold, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

