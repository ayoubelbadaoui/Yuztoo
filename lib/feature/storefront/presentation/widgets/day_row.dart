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
    if (slots.isNotEmpty) widget.onSave(slots);
    setState(() => _expanded = false);
  }

  void _addSlot() {
    setState(() {
      _editableSlots.add(const TimeSlot(start: '8h', end: '12h'));
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

