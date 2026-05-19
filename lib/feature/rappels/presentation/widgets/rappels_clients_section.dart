import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import 'rappels_section_header.dart';

part 'rappels_clients_section.part.dart';

/// "Nouveaux clients et Passage" section of the Rappels screen.
class RappelsClientsSection extends StatelessWidget {
  const RappelsClientsSection({
    super.key,
    required this.connectedClientsThisMonth,
    required this.validatedPassagesThisMonth,
    this.onAutoTap,
  });

  /// Clients connectés ce mois (Firestore `rappels_monthly_connected_clients`).
  final int connectedClientsThisMonth;

  /// Passages validés ce mois (Firestore `rappels_monthly_validated_passages`).
  final int validatedPassagesThisMonth;

  /// Tapping the toggle shortcut scrolls to the toggles section.
  final VoidCallback? onAutoTap;

  @override
  Widget build(BuildContext context) => _buildRappelsClientsBody(context);
}
