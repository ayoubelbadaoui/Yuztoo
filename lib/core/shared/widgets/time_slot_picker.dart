import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../feature/storefront/domain/entities/business_hours.dart'
    show normalizeTimeString;
import '../../../feature/storefront/presentation/widgets/storefront_colors.dart';
import 'cupertino_picker_sheet.dart';

/// A row with two tappable chips: [Start ▾] → [End ▾].
/// Tapping either opens a bottom sheet of predefined time choices.
/// Stored values use the same string format as the existing `TimeSlot` entity
/// (`'8h'`, `'12h30'`) so no Firestore migration is needed.
class TimeSlotPicker extends StatelessWidget {
  const TimeSlotPicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartChanged,
    required this.onEndChanged,
    this.enabled = true,
  });

  final String startTime;
  final String endTime;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TimeChip(
          label: startTime,
          prefix: 'Début',
          enabled: enabled,
          onTap: () => _pickTime(context, current: startTime, onPicked: onStartChanged),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '→',
            style: GoogleFonts.outfit(
              color: StorefrontColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        _TimeChip(
          label: endTime,
          prefix: 'Fin',
          enabled: enabled,
          onTap: () => _pickTime(context, current: endTime, onPicked: onEndChanged),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context, {
    required String current,
    required ValueChanged<String> onPicked,
  }) async {
    final initial = _parseToDateTime(current);
    final picked = await showYuztooCupertinoTimePicker(
      context: context,
      initial: initial,
      minuteInterval: 5,
    );
    if (picked != null) {
      onPicked(_format(picked));
    }
  }

  /// Parses the canonical `'Nh'` / `'NhMM'` storage format (and a couple of
  /// legacy variants) into a DateTime so the wheel can be seeded. Returns 8h00
  /// for anything unparseable so the picker still opens on a sensible default.
  static DateTime _parseToDateTime(String raw) {
    final s = normalizeTimeString(raw);
    final hMatch = RegExp(r'^(\d{1,2})h(\d{0,2})$').firstMatch(s);
    final today = DateTime.now();
    if (hMatch == null) {
      return DateTime(today.year, today.month, today.day, 8);
    }
    final h = int.parse(hMatch.group(1)!);
    final mStr = hMatch.group(2)!;
    final m = mStr.isEmpty ? 0 : int.parse(mStr);
    return DateTime(today.year, today.month, today.day, h, m);
  }

  static String _format(DateTime d) {
    return d.minute == 0
        ? '${d.hour}h'
        : '${d.hour}h${d.minute.toString().padLeft(2, '0')}';
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.prefix,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String prefix;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prefix,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: StorefrontColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: StorefrontColors.primaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: StorefrontColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
