import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../core/shared/widgets/cupertino_picker_sheet.dart';
import '../../application/personal_birthday_broadcast_detector.dart';
import '../../domain/entities/scheduled_notification.dart';
import '../../domain/entities/sent_notification.dart';
import '../../infrastructure/scheduled_notification_repository_provider.dart';
import 'notification_templates_widgets.dart';
import 'rappels_section_header.dart';

part 'quick_send_section.part.dart';

const _scheduleMinuteInterval = 5;

/// [CupertinoDatePicker] with [minuteInterval] requires
/// `initialDateTime.minute % interval == 0` or the picker asserts (red screen).
DateTime alignDateTimeToMinuteInterval(DateTime value, int intervalMinutes) {
  if (intervalMinutes <= 1) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }
  final base = DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
  );
  final remainder = base.minute % intervalMinutes;
  if (remainder == 0) return base;
  return base.add(Duration(minutes: intervalMinutes - remainder));
}

/// Compose + quick-send section rendered inside the Rappels screen.
/// Lets the merchant type a message, pick an audience, and blast it to all
/// matching followers in one tap. Shows the last [historyLimit] sent messages.
class QuickSendSection extends ConsumerStatefulWidget {
  const QuickSendSection({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.createdByUid,
    required this.onSend,
    this.history = const [],
    this.historyLoading = false,
    this.quotaLabel = '0/5',
    this.quotaExceeded = false,
  });

  final String merchantId;
  final String merchantName;

  /// Firebase Auth uid of the merchant owner (`created_by_uid` in Firestore rules).
  final String createdByUid;

  /// Called with (text, audience, segments) when the send button is pressed.
  final Future<void> Function(
    String text,
    String audience,
    List<String> segments,
  ) onSend;

  /// Pre-loaded sent notification history (newest first).
  final List<SentNotification> history;
  final bool historyLoading;

  /// E.g. "2/5" — shown as quota indicator.
  final String quotaLabel;

  /// When true, the send button is disabled.
  final bool quotaExceeded;

  @override
  ConsumerState<QuickSendSection> createState() => _QuickSendSectionState();
}

class _QuickSendSectionState extends ConsumerState<QuickSendSection> {
  final TextEditingController _ctrl = TextEditingController();
  int _audienceIndex = 0; // 0 = Tous, 1..N = segments
  bool _sending = false;

  /// When non-null, the send button is in "Programmer" mode and tapping
  /// it schedules the notification at this instant instead of firing
  /// immediately. Cleared when the user toggles scheduling off OR after
  /// a successful schedule (so the next compose starts fresh).
  DateTime? _scheduledAt;

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

  // Maps the persisted (audience, segments) pair back into the
  // _audienceIndex / chip selection so loading a template restores the
  // exact same UI state. A persisted "Certains clients" with an
  // unknown segment falls back to "Tous" (index 0) — the form is
  // never put into an inconsistent state, and the merchant can re-pick.
  void _applyTemplate(TemplatePick pick) {
    setState(() {
      _ctrl.text = pick.text;
      _ctrl.selection = TextSelection.collapsed(offset: pick.text.length);
      if (pick.audience == 'Tous mes clients' || pick.segments.isEmpty) {
        _audienceIndex = 0;
      } else {
        final key = pick.segments.first;
        final i = _audienceOptions
            .indexWhere((o) => o.segmentKey == key);
        _audienceIndex = i >= 0 ? i : 0;
      }
    });
  }

  Future<void> _openTemplatesPicker() async {
    final pick = await showTemplatesPickerSheet(
      context: context,
      merchantId: widget.merchantId,
    );
    if (pick == null || !mounted) return;
    _applyTemplate(pick);
  }

  Future<void> _saveCurrentAsTemplate() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Composez un message avant d\'enregistrer.',
            style: merchantSnackBarTextOnDark(),
          ),
          backgroundColor: MerchantColors.bgHeader,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final option = _audienceOptions[_audienceIndex];
    final audience =
        _audienceIndex == 0 ? 'Tous mes clients' : 'Certains clients';
    final segments =
        _audienceIndex == 0 ? const <String>[] : [option.segmentKey];
    final saved = await showSaveTemplateDialog(
      context: context,
      ref: ref,
      merchantId: widget.merchantId,
      text: text,
      audience: audience,
      segments: segments,
    );
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Template enregistré ✓',
          style: merchantSnackBarTextOnGold(),
        ),
        backgroundColor: MerchantColors.gold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Opens an iPhone-style scroll-wheel sheet for date+time. Returns the
  // chosen DateTime in local time, or null on cancel. Floors at "now + 5
  // minutes" so the server-side "earliest" check can't reject what the
  // merchant confirmed in the picker.
  Future<DateTime?> _pickScheduledAt() async {
    final now = DateTime.now();
    final earliest = alignDateTimeToMinuteInterval(
      now.add(const Duration(minutes: 6)),
      _scheduleMinuteInterval,
    );
    final latest = alignDateTimeToMinuteInterval(
      now.add(const Duration(days: 90)),
      _scheduleMinuteInterval,
    );
    final initialRaw = _scheduledAt ?? now.add(const Duration(hours: 1));
    final initial = alignDateTimeToMinuteInterval(
      initialRaw.isBefore(earliest) ? earliest : initialRaw,
      _scheduleMinuteInterval,
    );

    final picked = await showYuztooCupertinoDateTimePicker(
      context: context,
      initial: initial,
      minimumDate: earliest,
      maximumDate: latest,
      minuteInterval: _scheduleMinuteInterval,
    );
    if (picked == null) return null;
    return alignDateTimeToMinuteInterval(picked, _scheduleMinuteInterval);
  }

  Future<void> _toggleScheduleOn() async {
    final picked = await _pickScheduledAt();
    if (!mounted || picked == null) return;
    setState(() => _scheduledAt = picked);
  }

  void _toggleScheduleOff() {
    setState(() => _scheduledAt = null);
  }

  Future<void> _onSendTap() async {
    if (_ctrl.text.trim().isEmpty || widget.quotaExceeded) return;

    final option = _audienceOptions[_audienceIndex];
    final audience =
        _audienceIndex == 0 ? 'Tous mes clients' : 'Certains clients';
    final segments =
        _audienceIndex == 0 ? const <String>[] : [option.segmentKey];

    // Guard a common misuse: typing "Joyeux anniversaire 🎂" and blasting
    // it to every follower bypasses the per-client birthday auto-trigger
    // and pushes a personal wish to people whose birthday isn't today.
    // We only surface a soft confirmation — the merchant can still send
    // through (e.g. for a "anniversaire de notre commerce" broadcast).
    final isBroadcast = audience == 'Tous mes clients';
    if (isLikelyPersonalBirthdayBroadcast(
      text: _ctrl.text,
      isBroadcastAudience: isBroadcast,
    )) {
      final confirmed = await _confirmPersonalBirthdayBroadcast();
      if (!mounted || confirmed != true) return;
    }

    setState(() => _sending = true);

    try {
      final scheduled = _scheduledAt;
      if (scheduled != null) {
        // Scheduling path — does NOT touch widget.onSend; we don't burn
        // weekly quota at scheduling time (the CF will, at fire time).
        final repo =
            ref.read(scheduledNotificationRepositoryProvider);
        final result = await repo.schedule(
          merchantId: widget.merchantId,
          createdByUid: widget.createdByUid,
          text: _ctrl.text.trim(),
          audience: audience,
          segments: segments,
          scheduledAt: alignDateTimeToMinuteInterval(
            scheduled,
            _scheduleMinuteInterval,
          ),
        );
        if (!mounted) return;
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  failure.message,
                  style: merchantSnackBarTextOnWarmAccent(),
                ),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Notification programmée ✓',
                  style: merchantSnackBarTextOnGold(),
                ),
                backgroundColor: MerchantColors.gold,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _ctrl.clear();
            setState(() => _scheduledAt = null);
          },
        );
      } else {
        await widget.onSend(_ctrl.text.trim(), audience, segments);
        if (mounted) _ctrl.clear();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancelScheduled(ScheduledNotification s) async {
    final repo = ref.read(scheduledNotificationRepositoryProvider);
    final result = await repo.cancel(
      merchantId: widget.merchantId,
      scheduledId: s.id,
    );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure.message,
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Programmation annulée',
            style: merchantSnackBarTextOnDark(fontWeight: FontWeight.w600),
          ),
          backgroundColor: MerchantColors.bgHeader,
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
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
