import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/active_notification.dart';

part 'active_notification_card.part.dart';

/// Active notification card – friendly design with:
///  • On/Off toggle for quick enable/disable
///  • Trigger & audience labels as pills
///  • Clear edit & delete action buttons
class ActiveNotificationCard extends StatelessWidget {
  const ActiveNotificationCard({
    super.key,
    required this.notification,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onTest,
  });

  final ActiveNotification notification;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Called when the merchant taps "Tester" to send a test push to themselves.
  final VoidCallback? onTest;

  @override
  Widget build(BuildContext context) => _buildActiveNotificationCard(context);
}
