import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/infrastructure/firebase_providers.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../auth/core/application/state/auth_state.dart';
import '../../../client_notification/domain/entities/client_notification.dart';
import '../../../client_notification/infrastructure/client_notification_repository_provider.dart';
import '../../application/auto_notification_health_check.dart';

part 'auto_notification_health_panel.part.dart';

/// Live diagnostic panel for the auto-notification pipeline.
///
/// Shown above the templates list on the merchant's "Notifications
/// automatiques" screen so they can SEE in one glance whether their
/// pipeline is fully operational, and tap a single button to send
/// themselves a real test push (validates FCM end-to-end on this
/// device).
///
/// Every gate is read live from Firestore + the FCM SDK. No state is
/// cached on the widget; pulling to refresh re-runs the whole check.
class AutoNotificationHealthPanel extends ConsumerStatefulWidget {
  const AutoNotificationHealthPanel({
    super.key,
    required this.merchantId,
    required this.merchantName,
  });

  final String merchantId;
  final String merchantName;

  @override
  ConsumerState<AutoNotificationHealthPanel> createState() =>
      _AutoNotificationHealthPanelState();
}

class _AutoNotificationHealthPanelState
    extends ConsumerState<AutoNotificationHealthPanel> {
  late Future<AutoNotificationHealthReport> _future;
  bool _expanded = false;
  bool _sendingTest = false;

  @override
  void initState() {
    super.initState();
    _future = _runCheck();
  }

  @override
  void didUpdateWidget(covariant AutoNotificationHealthPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.merchantId != widget.merchantId) {
      _future = _runCheck();
    }
  }

  Future<AutoNotificationHealthReport> _runCheck() {
    final firestore = ref.read(firebaseFirestoreProvider);
    final authState = ref.read(auth_providers.authStateProvider);
    final userId = authState is Authenticated ? authState.user.id : '';
    final checker = AutoNotificationHealthChecker(firestore: firestore);
    return checker.check(userId: userId, merchantId: widget.merchantId);
  }

  void _refresh() {
    setState(() {
      _future = _runCheck();
    });
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
