import 'package:flutter/material.dart';

import '../../domain/entities/business_hours.dart';
import 'gold_switch.dart';
import 'storefront_colors.dart';

/// A single day row inside the hours card.
///
/// Features:
///  • Gold toggle to open/close the day
///  • Status dot (green = open, grey = closed)
///  • "Voir (N créneaux)" expand pill
///  • Inline time-slot editor with save confirmation
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

  final List<TextEditingController> _startCtrls = [];
  final List<TextEditingController> _endCtrls = [];

  bool get _isOpen =>
      widget.dayHours.isEnabled &&
      !widget.dayHours.isClosed &&
      !widget.isDisabled;

  bool get _hasSlots => widget.dayHours.timeSlots.isNotEmpty && _isOpen;
  int get _slotCount => widget.dayHours.timeSlots.length;

  @override
  void didUpdateWidget(covariant DayRow old) {
    super.didUpdateWidget(old);
    if (!_expanded) _syncControllers();
  }

  void _syncControllers() {
    _disposeControllers();
    for (final slot in widget.dayHours.timeSlots) {
      _startCtrls.add(TextEditingController(text: slot.start));
      _endCtrls.add(TextEditingController(text: slot.end));
    }
  }

  void _disposeControllers() {
    for (final c in _startCtrls) {
      c.dispose();
    }
    for (final c in _endCtrls) {
      c.dispose();
    }
    _startCtrls.clear();
    _endCtrls.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _toggleExpand() {
    if (!_hasSlots) return;
    setState(() {
      if (!_expanded) {
        _syncControllers();
        _expanded = true;
      } else {
        _expanded = false;
      }
    });
  }

  void _saveChanges() {
    final slots = <TimeSlot>[];
    for (int i = 0; i < _startCtrls.length; i++) {
      final s = _startCtrls[i].text.trim();
      final e = _endCtrls[i].text.trim();
      if (s.isNotEmpty && e.isNotEmpty) {
        slots.add(TimeSlot(start: s, end: e));
      }
    }
    if (slots.isNotEmpty) widget.onSave(slots);
    setState(() => _expanded = false);
  }

  void _addSlot() {
    setState(() {
      _startCtrls.add(TextEditingController(text: '8h'));
      _endCtrls.add(TextEditingController(text: '12h'));
    });
  }

  void _removeSlot(int index) {
    if (_startCtrls.length <= 1) return;
    setState(() {
      _startCtrls[index].dispose();
      _endCtrls[index].dispose();
      _startCtrls.removeAt(index);
      _endCtrls.removeAt(index);
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

  Widget _buildSummaryPill() {
    final label = _expanded
        ? 'Masquer'
        : 'Voir ($_slotCount créneau${_slotCount > 1 ? 'x' : ''})';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: StorefrontColors.primaryGold,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: StorefrontColors.primaryGold,
          ),
        ],
      ),
    );
  }

  // ── inline editor ──────────────────────────────────────────────────────────

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          children: [
            for (int i = 0; i < _startCtrls.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildSlotRow(i),
            ],
            const SizedBox(height: 10),
            // ── add slot ──
            GestureDetector(
              onTap: _addSlot,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      StorefrontColors.primaryGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        StorefrontColors.primaryGold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: StorefrontColors.primaryGold),
                    SizedBox(width: 4),
                    Text(
                      'Ajouter un créneau',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: StorefrontColors.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── save ──
            GestureDetector(
              onTap: _saveChanges,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: StorefrontColors.primaryGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotRow(int index) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: StorefrontColors.primaryGold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildTimeField(_startCtrls[index])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded,
              size: 14, color: Colors.grey[400]),
        ),
        Expanded(child: _buildTimeField(_endCtrls[index])),
        if (_startCtrls.length > 1) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeSlot(index),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: StorefrontColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: StorefrontColors.primaryGold, width: 2),
        ),
      ),
    );
  }
}

