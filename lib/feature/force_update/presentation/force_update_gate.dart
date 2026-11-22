import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import 'force_update_screen.dart';

/// Wraps the whole app shell. When CRM publishes a mandatory floor above the
/// installed build, replaces [child] with [ForceUpdateScreen].
class ForceUpdateGate extends ConsumerWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(forceUpdateDecisionProvider).valueOrNull;
    if (decision != null && decision.required) {
      return ForceUpdateScreen(decision: decision);
    }
    return child;
  }
}
