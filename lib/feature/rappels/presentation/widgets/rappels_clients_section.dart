import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import 'rappels_section_header.dart';

part 'rappels_clients_section.part.dart';

/// "Nouveaux clients et Passages" monthly overview (Vos clients › Aperçu).
class RappelsClientsSection extends StatelessWidget {
  const RappelsClientsSection({
    super.key,
    required this.connectedClientsThisMonth,
    required this.validatedPassagesThisMonth,
    this.onAutoTap,
    this.padding = const EdgeInsets.all(24),
    this.showBottomBorder = true,
  });

  /// Clients connectés ce mois (Firestore `rappels_monthly_connected_clients`).
  final int connectedClientsThisMonth;

  /// Passages validés ce mois (Firestore `rappels_monthly_validated_passages`).
  final int validatedPassagesThisMonth;

  /// Tapping the "Auto" shortcut opens the validation toggles; the shortcut
  /// is hidden when null.
  final VoidCallback? onAutoTap;

  final EdgeInsetsGeometry padding;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) => _buildRappelsClientsBody(context);
}
