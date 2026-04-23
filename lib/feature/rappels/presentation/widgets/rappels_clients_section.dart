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
    this.pendingLoyaltyPassagesToConfirm = 0,
    this.isManualPassageValidation = false,
    this.onConfirmPendingPassagesTap,
    this.onAutoTap,
  });

  /// Clients connectés ce mois (Firestore `rappels_monthly_connected_clients`).
  final int connectedClientsThisMonth;

  /// Passages validés ce mois (Firestore `rappels_monthly_validated_passages`).
  final int validatedPassagesThisMonth;

  /// Somme des `pending_passages` (fidélité à validation manuelle).
  final int pendingLoyaltyPassagesToConfirm;

  /// Vrai si le programme exige une validation marchand des passages.
  final bool isManualPassageValidation;

  /// Défile vers la liste « Passages à valider » (fidélité).
  final VoidCallback? onConfirmPendingPassagesTap;

  /// Tapping "Auto" badge scrolls to the toggles section to change mode.
  final VoidCallback? onAutoTap;

  @override
  Widget build(BuildContext context) => _buildRappelsClientsBody(context);
}
