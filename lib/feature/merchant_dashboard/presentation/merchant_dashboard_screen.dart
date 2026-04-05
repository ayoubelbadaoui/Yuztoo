import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../l10n/app_localizations.dart';

part 'merchant_dashboard_screen.part.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key, required this.onNavigate});

  static String get path => '/merchant-dashboard';

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => _buildDashboardScrollView(context);
}
