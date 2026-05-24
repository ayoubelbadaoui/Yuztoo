import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shared/widgets/snackbar.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../application/active_validation_providers.dart';
import '../domain/entities/active_validation_request.dart';
import 'active_validation_ui.dart';

/// Injectable hook for tests — production uses [showMerchantActiveValidationSheet].
typedef ShowMerchantPassageValidationSheetFn = Future<void> Function({
  required BuildContext context,
  required Merchant merchant,
  required ActiveValidationRequest session,
});

final showMerchantPassageValidationSheetProvider =
    Provider<ShowMerchantPassageValidationSheetFn>(
  (ref) => showMerchantActiveValidationSheet,
);

/// Prepares the session and opens the merchant validation sheet.
///
/// Set [connectMerchantBle] when the merchant explicitly confirmed proximity
/// (detection sheet, BLE scan pick). This stamps `merchant_ble_connected_at`
/// before the sheet opens. Vitrine and shell auto-popup use `false`.
///
/// Returns `false` when preparation failed.
Future<bool> openMerchantPassageValidation({
  required WidgetRef ref,
  required BuildContext context,
  required Merchant merchant,
  required ActiveValidationRequest session,
  bool connectMerchantBle = false,
}) async {
  var workingSession = session;

  if (connectMerchantBle &&
      session.isBle &&
      !session.isMerchantBleConnected) {
    final acceptResult =
        await ref.read(acceptBlePassageAsMerchantProvider).call(
              merchantId: merchant.id,
              clientUid: session.clientUid,
              existingSession: session,
            );
    if (!context.mounted) return false;
    final accepted = acceptResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message,
              style: merchantSnackBarTextOnDark(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
        return null;
      },
      (s) => s,
    );
    if (accepted == null) return false;
    workingSession = accepted;
  }

  final prepared =
      await ref.read(prepareMerchantPassageValidationProvider).call(
            merchantId: merchant.id,
            session: workingSession,
          );

  if (!context.mounted) return false;

  return prepared.fold(
    (failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure.message,
            style: merchantSnackBarTextOnDark(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    },
    (readySession) async {
      if (!context.mounted) return false;
      await ref.read(showMerchantPassageValidationSheetProvider)(
        context: context,
        merchant: merchant,
        session: readySession,
      );
      return true;
    },
  );
}
