import 'package:flutter/material.dart';
import 'storefront_colors.dart';

/// Merchant information section with name, activity, and edit button
class MerchantInfoSection extends StatelessWidget {
  const MerchantInfoSection({
    super.key,
    required this.merchantName,
    required this.description,
    required this.city,
    required this.loyaltyEnabled,
    required this.isVerified,
    this.onEdit,
  });

  final String merchantName;
  final String description;
  final String city;
  final bool loyaltyEnabled;
  final bool isVerified;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        merchantName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: StorefrontColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified,
                        size: 22,
                        color: StorefrontColors.primaryGold,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description.trim().isEmpty
                      ? 'Description non renseignée'
                      : description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: StorefrontColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: StorefrontColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        city.trim().isEmpty ? 'Ville non renseignée' : city,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: StorefrontColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: loyaltyEnabled
                        ? StorefrontColors.primaryGold.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    loyaltyEnabled ? 'Fidélité active' : 'Fidélité inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: loyaltyEnabled
                          ? StorefrontColors.navyDark
                          : StorefrontColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: StorefrontColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
