import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

class MerchantStatsScreen extends StatelessWidget {
  const MerchantStatsScreen({super.key, required this.onBack});

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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Text(
                  'Statistiques',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                _Chip(text: 'Cette semaine', isPrimary: true),
                SizedBox(width: 8),
                _Chip(text: 'Ce mois'),
                SizedBox(width: 8),
                _Chip(text: 'Cette année'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: const [
                _MetricCard(
                  icon: Icons.group_outlined,
                  value: '248',
                  label: 'Clients actifs',
                  trend: '+12%',
                  iconColor: Color(0xFF1E64D0),
                ),
                _MetricCard(
                  icon: Icons.star_border,
                  value: '3,245',
                  label: 'Points distribués',
                  trend: '+8%',
                  iconColor: YColors.secondary,
                ),
                _MetricCard(
                  icon: Icons.calendar_today_outlined,
                  value: '1,432',
                  label: 'Visites ce mois',
                  trend: '-3%',
                  isNegative: true,
                  iconColor: Color(0xFF1E9E5B),
                ),
                _MetricCard(
                  icon: Icons.trending_up,
                  value: '4.5',
                  label: 'Note moyenne',
                  trend: '+18%',
                  iconColor: Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visites hebdomadaires',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= weeklyVisits.length)
                                        return const SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          weeklyVisits[index]['day'] as String,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(),
                                rightTitles: const AxisTitles(),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 20,
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(weeklyVisits.length, (
                                index,
                              ) {
                                final visits =
                                    weeklyVisits[index]['visits'] as int;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: visits.toDouble(),
                                      color: YColors.secondary,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(6),
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                            show: true,
                                            toY: 120,
                                            color: YColors.accent,
                                          ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Évolution des points',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: LineChart(
                            LineChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 500,
                                drawVerticalLine: false,
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= monthlyPoints.length)
                                        return const SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          monthlyPoints[index]['month']
                                              as String,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 42,
                                  ),
                                ),
                                topTitles: const AxisTitles(),
                                rightTitles: const AxisTitles(),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(monthlyPoints.length, (
                                    index,
                                  ) {
                                    final points =
                                        monthlyPoints[index]['points'] as num;
                                    return FlSpot(
                                      index.toDouble(),
                                      points.toDouble(),
                                    );
                                  }),
                                  color: YColors.secondary,
                                  barWidth: 4,
                                  isCurved: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                              color: Colors.white,
                                              radius: 4,
                                              strokeWidth: 3,
                                              strokeColor: YColors.secondary,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meilleurs clients',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: const [
                            _TopClient(
                              name: 'Mohammed A.',
                              points: 245,
                              visits: 38,
                            ),
                            SizedBox(height: 10),
                            _TopClient(
                              name: 'Fatima Z.',
                              points: 180,
                              visits: 24,
                            ),
                            SizedBox(height: 10),
                            _TopClient(
                              name: 'Ahmed K.',
                              points: 156,
                              visits: 31,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
    this.isNegative = false,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final String trend;
  final bool isNegative;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final trendColor = isNegative ? Colors.red : const Color(0xFF1E9E5B);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor),
                Row(
                  children: [
                    Icon(
                      isNegative ? Icons.trending_down : Icons.trending_up,
                      size: 14,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: YColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _TopClient extends StatelessWidget {
  const _TopClient({
    required this.name,
    required this.points,
    required this.visits,
  });
  final String name;
  final int points;
  final int visits;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: YColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '$visits visites',
                  style: const TextStyle(color: YColors.muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$points',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Text(
              'points',
              style: TextStyle(color: YColors.muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.isPrimary = false});
  final String text;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? YColors.secondary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? Colors.transparent : YColors.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isPrimary ? Colors.white : YColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
