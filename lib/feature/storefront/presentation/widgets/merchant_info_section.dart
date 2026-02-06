import 'package:flutter/material.dart';
import 'storefront_colors.dart';

/// Merchant information section with name, activity, and edit button
class MerchantInfoSection extends StatelessWidget {
  const MerchantInfoSection({
    super.key,
    required this.merchantName,
    required this.businessActivity,
    required this.isVerified,
    this.onEdit,
  });

  final String merchantName;
  final String businessActivity;
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
                  businessActivity,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: StorefrontColors.textSecondary,
                    height: 1.4,
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

