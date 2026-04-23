import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/sent_notification.dart';
import 'rappels_section_header.dart';

part 'quick_send_section.part.dart';

/// Compose + quick-send section rendered inside the Rappels screen.
/// Lets the merchant type a message, pick an audience, and blast it to all
/// matching followers in one tap. Shows the last [historyLimit] sent messages.
class QuickSendSection extends ConsumerStatefulWidget {
  const QuickSendSection({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.onSend,
    this.history = const [],
    this.historyLoading = false,
  });

  final String merchantId;
  final String merchantName;

  /// Called with (text, audience, segments) when the send button is pressed.
  final Future<void> Function(
    String text,
    String audience,
    List<String> segments,
  ) onSend;

  /// Pre-loaded sent notification history (newest first).
  final List<SentNotification> history;
  final bool historyLoading;

  @override
  ConsumerState<QuickSendSection> createState() => _QuickSendSectionState();
}

class _QuickSendSectionState extends ConsumerState<QuickSendSection> {
  final TextEditingController _ctrl = TextEditingController();
  int _audienceIndex = 0; // 0 = Tous, 1..N = segments
  bool _sending = false;

  static const _audienceOptions = [
    _AudienceOption('Tous', Icons.groups_outlined, ''),
    _AudienceOption('VIP', Icons.workspace_premium_outlined, 'vip'),
    _AudienceOption('Habitués', Icons.repeat_rounded, 'habitue'),
    _AudienceOption('Nouveaux', Icons.person_add_outlined, 'nouveau'),
    _AudienceOption('Inactifs', Icons.schedule_outlined, 'inactif'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onSendTap() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _sending = true);

    final option = _audienceOptions[_audienceIndex];
    final audience =
        _audienceIndex == 0 ? 'Tous mes clients' : 'Certains clients';
    final segments =
        _audienceIndex == 0 ? const <String>[] : [option.segmentKey];

    try {
      await widget.onSend(_ctrl.text.trim(), audience, segments);
      if (mounted) _ctrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
  @override
  Widget build(BuildContext context) => _buildBody(context);
}

class _AudienceOption {
  final String label;
  final IconData icon;
  final String segmentKey;
  const _AudienceOption(this.label, this.icon, this.segmentKey);
}
