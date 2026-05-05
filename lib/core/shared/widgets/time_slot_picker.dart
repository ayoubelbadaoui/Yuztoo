import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/merchant_colors.dart';

/// Predefined half-hour time slots from 06h00 to 23h30.
const _kTimeOptions = [
  '6h', '6h30', '7h', '7h30', '8h', '8h30',
  '9h', '9h30', '10h', '10h30', '11h', '11h30',
  '12h', '12h30', '13h', '13h30', '14h', '14h30',
  '15h', '15h30', '16h', '16h30', '17h', '17h30',
  '18h', '18h30', '19h', '19h30', '20h', '20h30',
  '21h', '21h30', '22h', '22h30', '23h', '23h30',
];

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
              color: MerchantColors.textGrey,
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

  void _pickTime(
    BuildContext context, {
    required String current,
    required ValueChanged<String> onPicked,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MerchantColors.bgHeader,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TimePickerSheet(
        current: current,
        onPicked: (v) {
          Navigator.of(ctx).pop();
          onPicked(v);
        },
      ),
    );
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
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.35),
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
                    color: MerchantColors.textGrey,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: MerchantColors.textGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerSheet extends StatelessWidget {
  const _TimePickerSheet({
    required this.current,
    required this.onPicked,
  });

  final String current;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: MerchantColors.textGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choisir l\'heure',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: _kTimeOptions.length,
              itemBuilder: (ctx, i) {
                final time = _kTimeOptions[i];
                final isSelected = time == current;
                return GestureDetector(
                  onTap: () => onPicked(time),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MerchantColors.gold
                          : MerchantColors.navyCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? MerchantColors.gold
                            : MerchantColors.gold.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        time,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? MerchantColors.bgHeader
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
