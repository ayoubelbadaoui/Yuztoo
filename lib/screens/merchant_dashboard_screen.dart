import 'package:flutter/material.dart';
import '../theme.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  final stats = const [
    _StatCard(
        label: 'Clients actifs',
        value: '248',
        change: '+12',
        icon: Icons.group_outlined,
        color: Color(0xFF1E64D0)),
    _StatCard(
        label: 'Visites ce mois',
        value: '1,432',
        change: '+8%',
        icon: Icons.trending_up,
        color: Color(0xFF1E9E5B)),
    _StatCard(
        label: 'Points distribués',
        value: '3,245',
        change: '+156',
        icon: Icons.star_border,
        color: YColors.secondary),
    _StatCard(
        label: 'Promotions actives',
        value: '5',
        change: '2 exp.',
        icon: Icons.card_giftcard,
        color: Color(0xFF8B5CF6)),
  ];

  final List<Activity> recentActivity = const [
    Activity(
        customer: 'Mohammed A.',
        action: 'Scan QR',
        points: 10,
        time: 'Il y a 5 min'),
    Activity(
        customer: 'Fatima Z.',
        action: 'Récompense utilisée',
        points: -50,
        time: 'Il y a 12 min'),
    Activity(
        customer: 'Ahmed K.',
        action: 'Scan QR',
        points: 10,
        time: 'Il y a 23 min'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: YColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mon commerce',
                            style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 4),
                        Text('Café Central',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => onNavigate('settings'),
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.greenAccent),
                    SizedBox(width: 6),
                    Text('Ouvert', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final stat = stats[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(stat.icon, color: stat.color),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(stat.change,
                                  style: const TextStyle(
                                      color: Color(0xFF1E9E5B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(stat.value,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(stat.label,
                            style: const TextStyle(color: YColors.muted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Actions rapides',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _QuickAction(
                      title: 'Mon QR Code',
                      subtitle: 'Afficher le code',
                      icon: Icons.qr_code_2,
                      background: YColors.secondary.withValues(alpha: 0.1),
                      iconColor: YColors.secondary,
                      onTap: () => onNavigate('qr-code'),
                    ),
                    _QuickAction(
                      title: 'Promotions',
                      subtitle: 'Gérer les offres',
                      icon: Icons.card_giftcard,
                      background: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () => onNavigate('promotions'),
                    ),
                    _QuickAction(
                      title: 'Messages',
                      subtitle: '3 non lus',
                      icon: Icons.chat_bubble_outline,
                      background: const Color(0xFFE8F1FF),
                      iconColor: const Color(0xFF1E64D0),
                      onTap: () => onNavigate('messages'),
                    ),
                    _QuickAction(
                      title: 'Réservations',
                      subtitle: '8 aujourd\'hui',
                      icon: Icons.calendar_today_outlined,
                      background: const Color(0xFFE9F5EE),
                      iconColor: const Color(0xFF1E9E5B),
                      onTap: () => onNavigate('reservations'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Activité récente',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    TextButton(
                        onPressed: () => onNavigate('clients'),
                        child: const Text('Tout voir')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: recentActivity
                  .map((activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(activity.customer,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(activity.action,
                                        style: const TextStyle(
                                            color: YColors.muted)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${activity.points > 0 ? '+' : ''}${activity.points} pts',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: activity.points > 0
                                            ? const Color(0xFF1E9E5B)
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(activity.time,
                                        style: const TextStyle(
                                            color: YColors.muted,
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: background, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: YColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.change,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
}

class Activity {
  final String customer;
  final String action;
  final int points;
  final String time;

  const Activity({
    required this.customer,
    required this.action,
    required this.points,
    required this.time,
  });
}
