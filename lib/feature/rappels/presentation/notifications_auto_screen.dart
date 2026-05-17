import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../client_notification/domain/entities/client_notification.dart';
import '../../client_notification/infrastructure/client_notification_repository_provider.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../application/providers.dart' as rappels_providers;
import '../domain/auto_notification_triggers.dart';
import '../domain/entities/active_notification.dart';
import 'widgets/active_notifications_list.dart';
import 'widgets/audience_section.dart';
import 'widgets/compose_section.dart';
import 'widgets/step_header.dart';
import 'widgets/trigger_grid.dart';

part 'notifications_auto_screen.part.dart';

/// Notifications automatiques screen – all data saved to Firestore.
class NotificationsAutoScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const NotificationsAutoScreen({super.key, this.onBack});

  @override
  ConsumerState<NotificationsAutoScreen> createState() =>
      _NotificationsAutoScreenState();
}

class _NotificationsAutoScreenState
    extends ConsumerState<NotificationsAutoScreen> {
  final TextEditingController _textCtrl = TextEditingController();

  int _clientSelection = 0;
  int _selectedTrigger = 0;
  List<String> _targetSegments = const [];
  int? _editingIndex;
  ActiveNotification? _editingNotification;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefront_providers.storefrontProvider);
    final merchantId = storefrontAsync.value?.id;
    final notificationsAsync = merchantId != null
        ? ref.watch(rappels_providers.autoNotificationsProvider(merchantId))
        : const AsyncValue<List<ActiveNotification>>.data([]);

    return _buildNotificationsAutoRoot(merchantId, notificationsAsync);
  }

  void _withSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _onClientSelectionChanged(int v) {
    _withSetState(() {
      _clientSelection = v;
      if (v == 0) _targetSegments = const []; // reset segments when switching to "Tous"
    });
  }

  void _onTriggerSelected(int i) {
    _withSetState(() => _selectedTrigger = i);
  }

  void _onSegmentToggled(String segment) {
    _withSetState(() {
      final list = List<String>.from(_targetSegments);
      list.contains(segment) ? list.remove(segment) : list.add(segment);
      _targetSegments = list;
    });
  }
}
