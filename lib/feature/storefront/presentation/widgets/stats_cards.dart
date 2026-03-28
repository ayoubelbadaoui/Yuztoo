import 'package:flutter/material.dart';
import 'storefront_colors.dart';

/// Stats cards showing profile completion and weekly views
class StatsCards extends StatelessWidget {
  const StatsCards({
    super.key,
    required this.profileCompletionPercentage,
    required this.weeklyViews,
    required this.weeklyViewsChange,
  });

  final int profileCompletionPercentage;
  final int weeklyViews;
  final double weeklyViewsChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ProfileCompletionCard(
                percentage: profileCompletionPercentage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeeklyViewsCard(
                views: weeklyViews,
                change: weeklyViewsChange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PROFIL COMPLÉTÉ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: StorefrontColors.primaryGold,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.primaryGold,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyViewsCard extends StatelessWidget {
  const _WeeklyViewsCard({
    required this.views,
    required this.change,
  });

  final int views;
  final double change;

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VUES / SEMAINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Show real number (0 for now, feature will be added later)
          if (views == 0)
            const Text(
              '0',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: StorefrontColors.textPrimary,
                height: 1.0,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$views',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: StorefrontColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? StorefrontColors.successGreen : Colors.red,
                    height: 1.0,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

