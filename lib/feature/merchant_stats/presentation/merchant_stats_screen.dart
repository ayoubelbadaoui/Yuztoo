import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../theme.dart';

part 'merchant_stats_screen.part.dart';

class MerchantStatsScreen extends StatelessWidget {
  const MerchantStatsScreen({super.key, required this.onBack});

  static String get path => '/merchant-stats';

  final VoidCallback onBack;

  final weeklyVisits = const [
    {'day': 'Lun', 'visits': 45},
    {'day': 'Mar', 'visits': 52},
    {'day': 'Mer', 'visits': 38},
    {'day': 'Jeu', 'visits': 61},
    {'day': 'Ven', 'visits': 78},
    {'day': 'Sam', 'visits': 92},
    {'day': 'Dim', 'visits': 48},
  ];

  final monthlyPoints = const [
    {'month': 'Sep', 'points': 1200},
    {'month': 'Oct', 'points': 1450},
    {'month': 'Nov', 'points': 1850},
    {'month': 'Déc', 'points': 2100},
    {'month': 'Jan', 'points': 2450},
  ];

  @override
  Widget build(BuildContext context) => _buildMerchantStatsBody(context);
}
