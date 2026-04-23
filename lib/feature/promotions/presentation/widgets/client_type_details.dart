import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/promotion.dart';

part 'client_type_details.part.dart';
/// Displays the detail panel for the currently selected [ClientType].
class ClientTypeDetails extends StatelessWidget {
  const ClientTypeDetails({
    super.key,
    required this.clientType,
    required this.selectedSegments,
    required this.selectedDistanceIndex,
    required this.onSegmentToggled,
    required this.onDistanceChanged,
  });

  final ClientType clientType;
  /// Active segment keys for premium type (multi-select).
  final Set<String> selectedSegments;
  final int selectedDistanceIndex;
  /// Called with the toggled segment key (e.g. 'vip', 'soutien', 'habitue').
  final ValueChanged<String> onSegmentToggled;
  final ValueChanged<int> onDistanceChanged;

  BoxDecoration get _detailBox => BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderStronger),
          width: 1,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return switch (clientType) {
      ClientType.gratuit => _buildGratuit(),
      ClientType.premium => _buildPremium(),
      ClientType.payant => _buildPayant(),
    };
  }
}

