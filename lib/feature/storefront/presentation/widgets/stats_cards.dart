import 'package:flutter/material.dart';
import 'storefront_colors.dart';

part 'stats_cards.part.dart';

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
  Widget build(BuildContext context) => _buildStatsCardsRow(context);
}
