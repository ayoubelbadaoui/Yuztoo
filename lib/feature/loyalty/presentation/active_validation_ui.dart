import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../domain/entities/active_validation_request.dart';
import 'widgets/active_validation_sheet.dart';

/// Opens the merchant validation bottom sheet (shared by shell + Vos clients).
Future<void> showMerchantActiveValidationSheet({
  required BuildContext context,
  required Merchant merchant,
  required ActiveValidationRequest session,
}) async {
  HapticFeedback.mediumImpact();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ActiveValidationSheet(
        merchant: merchant,
        session: session,
      ),
    ),
  );
}
