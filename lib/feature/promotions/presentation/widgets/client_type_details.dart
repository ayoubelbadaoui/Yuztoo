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
    required this.selectedTargetIndex,
    required this.selectedDistanceIndex,
    required this.onTargetChanged,
    required this.onDistanceChanged,
  });

  final ClientType clientType;
  final int selectedTargetIndex;
  final int selectedDistanceIndex;
  final ValueChanged<int> onTargetChanged;
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

