import 'package:flutter/material.dart';

import '../../../../../core/shared/widgets/time_slot_picker.dart';
import '../../domain/entities/business_hours.dart';
import 'gold_switch.dart';
import 'storefront_colors.dart';

part 'day_row.part.dart';

/// A single day row inside the hours card.
///
/// Features:
///  • Gold toggle to open/close the day
///  • Status dot (green = open, grey = closed)
///  • "Voir (N créneaux)" expand pill
///  • Inline time-slot editor using predefined time pickers (no free text)
class DayRow extends StatefulWidget {
  const DayRow({
    super.key,
    required this.dayHours,
    required this.isDisabled,
    required this.onToggle,
    required this.onSave,
  });

  final DayHours dayHours;
  final bool isDisabled;
  final ValueChanged<bool> onToggle;
  final ValueChanged<List<TimeSlot>> onSave;

  @override
  State<DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<DayRow> {
  bool _expanded = false;

  // Local editable slots (copied from widget when expanding).
  late List<TimeSlot> _editableSlots;

  bool get _isOpen =>
      widget.dayHours.isEnabled &&
      !widget.dayHours.isClosed &&
      !widget.isDisabled;

  bool get _hasSlots => widget.dayHours.timeSlots.isNotEmpty && _isOpen;
  int get _slotCount => widget.dayHours.timeSlots.length;

  void _syncSlots() {
    _editableSlots = List<TimeSlot>.from(widget.dayHours.timeSlots);
  }

  void _toggleExpand() {
    if (!_hasSlots) return;
    setState(() {
      if (!_expanded) {
        _syncSlots();
        _expanded = true;
      } else {
        _expanded = false;
      }
    });
  }

  void _saveChanges() {
    final slots = _editableSlots
        .where((s) => s.start.isNotEmpty && s.end.isNotEmpty)
        .toList();

    // Validate each slot: end must be strictly after start.
    for (final slot in slots) {
      final startMins = _timeToMinutes(slot.start);
      final endMins = _timeToMinutes(slot.end);
      if (endMins <= startMins) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'L\'heure de fin (${slot.end}) doit être après l\'heure de début (${slot.start})',
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }

    // Validate no overlapping slots.
    if (slots.length > 1) {
      final sorted = List<TimeSlot>.from(slots)
        ..sort((a, b) =>
            _timeToMinutes(a.start).compareTo(_timeToMinutes(b.start)));
      for (int i = 0; i < sorted.length - 1; i++) {
        final endMins = _timeToMinutes(sorted[i].end);
        final nextStartMins = _timeToMinutes(sorted[i + 1].start);
        if (nextStartMins < endMins) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Les créneaux ${sorted[i].display} et ${sorted[i + 1].display} se chevauchent',
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
      }
    }

    if (slots.isNotEmpty) widget.onSave(slots);
    setState(() => _expanded = false);
  }

  void _addSlot() {
    // Suggest a start 2 h after the last slot's end — avoids an obvious overlap
    // and gives the merchant a sensible second shift (e.g. 14h–18h after 8h–12h).
    String defaultStart = '8h';
    String defaultEnd = '12h';
    if (_editableSlots.isNotEmpty) {
      final lastEndMins = _timeToMinutes(_editableSlots.last.end);
      final suggestedStartMins = lastEndMins + 120; // 2 h break
      if (suggestedStartMins <= 23 * 60) {
        defaultStart = _minsToTimeString(suggestedStartMins);
        final suggestedEndMins = (suggestedStartMins + 240).clamp(0, 23 * 60 + 30);
        defaultEnd = _minsToTimeString(suggestedEndMins);
      } else {
        // Edge: last slot ends very late — offer a 23h–23h30 stub.
        defaultStart = '23h';
        defaultEnd = '23h30';
      }
    }
    setState(() {
      _editableSlots.add(TimeSlot(start: defaultStart, end: defaultEnd));
    });
  }

  void _removeSlot(int index) {
    if (_editableSlots.length <= 1) return;
    setState(() => _editableSlots.removeAt(index));
  }

  void _updateStart(int index, String value) {
    setState(() {
      _editableSlots[index] =
          TimeSlot(start: value, end: _editableSlots[index].end);
    });
  }

  void _updateEnd(int index, String value) {
    setState(() {
      _editableSlots[index] =
          TimeSlot(start: _editableSlots[index].start, end: value);
    });
  }

  // ── time helpers ───────────────────────────────────────────────────────────

  /// Converts a picker time string (e.g. '8h', '12h30') to total minutes.
  /// Returns 0 for unrecognized input.
  int _timeToMinutes(String time) {
    final match =
        RegExp(r'^(\d+)h(\d*)$').firstMatch(time.trim().toLowerCase());
    if (match == null) return 0;
    final h = int.parse(match.group(1)!);
    final m =
        match.group(2)!.isEmpty ? 0 : int.parse(match.group(2)!);
    return h * 60 + m;
  }

  /// Converts total minutes back to the picker string format ('8h', '12h30').
  /// Clamps to [6h, 23h30].
  String _minsToTimeString(int mins) {
    final clamped = mins.clamp(6 * 60, 23 * 60 + 30);
    final h = clamped ~/ 60;
    final m = clamped % 60;
    return m == 0 ? '${h}h' : '${h}h30';
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final opacity = widget.isDisabled ? 0.45 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          GestureDetector(
            onTap: _hasSlots ? _toggleExpand : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  GoldSwitch(
                    value: widget.dayHours.isEnabled,
                    onChanged: widget.isDisabled ? null : widget.onToggle,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOpen
                          ? StorefrontColors.successGreen
                          : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.dayHours.dayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _isOpen ? FontWeight.w600 : FontWeight.w500,
                      color: _isOpen
                          ? StorefrontColors.textPrimary
                          : StorefrontColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  _hasSlots
                      ? _buildSummaryPill()
                      : Text(
                          'Fermé',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[400],
                          ),
                        ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild:
                _expanded ? _buildEditor() : const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

