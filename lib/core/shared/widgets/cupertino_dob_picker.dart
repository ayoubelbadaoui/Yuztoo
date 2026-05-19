import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cupertino_picker_sheet.dart';

const _kMonthsFr = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

int _daysInMonth(int month1Based, int year) =>
    DateTime(year, month1Based + 1, 0).day;

/// iOS-style birth-date wheel (day / month / year) with one shared selection band.
Future<DateTime?> showCupertinoDobPicker({
  required BuildContext context,
  required DateTime initial,
  required DateTime minimum,
  required DateTime maximum,
}) async {
  return showCupertinoModalPopup<DateTime>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _DobPickerSheet(
      initial: initial,
      minimum: minimum,
      maximum: maximum,
    ),
  );
}

class _DobPickerSheet extends StatefulWidget {
  const _DobPickerSheet({
    required this.initial,
    required this.minimum,
    required this.maximum,
  });

  final DateTime initial;
  final DateTime minimum;
  final DateTime maximum;

  @override
  State<_DobPickerSheet> createState() => _DobPickerSheetState();
}

class _DobPickerSheetState extends State<_DobPickerSheet> {
  late int _day;
  late int _month;
  late int _year;

  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _yearCtrl;

  int get _yearCount => widget.maximum.year - widget.minimum.year + 1;
  int get _dayCount => _daysInMonth(_month + 1, _year);

  DateTime _clampToRange(DateTime value) {
    final d = DateTime(value.year, value.month, value.day);
    if (d.isBefore(widget.minimum)) return widget.minimum;
    if (d.isAfter(widget.maximum)) return widget.maximum;
    return d;
  }

  @override
  void initState() {
    super.initState();
    final seed = _clampToRange(widget.initial);
    final safeDay =
        seed.day.clamp(1, _daysInMonth(seed.month, seed.year));
    _day = safeDay - 1;
    _month = seed.month - 1;
    _year = seed.year;
    _dayCtrl = FixedExtentScrollController(initialItem: _day);
    _monthCtrl = FixedExtentScrollController(initialItem: _month);
    _yearCtrl = FixedExtentScrollController(
      initialItem: _year - widget.minimum.year,
    );
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _clampDayIfNeeded() {
    final max = (_dayCount - 1).clamp(0, 366);
    if (_day > max) {
      _day = max;
    }
    if (_dayCtrl.hasClients && _dayCtrl.selectedItem != _day) {
      _dayCtrl.jumpToItem(_day);
    }
  }

  void _onMonthChanged(int monthIndex) {
    _month = monthIndex;
    _clampDayIfNeeded();
    setState(() {});
  }

  void _onYearChanged(int yearIndex) {
    _year = widget.minimum.year + yearIndex;
    _clampDayIfNeeded();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return YuztooCupertinoPickerSheet(
      title: 'Date de naissance',
      unifiedSelectionOverlay: true,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () {
        final day = _day.clamp(0, _dayCount - 1) + 1;
        final month = _month + 1;
        Navigator.of(context).pop(DateTime(_year, month, day));
      },
      picker: Row(
        children: [
          Expanded(
            flex: 2,
            child: YuztooCupertinoScrollWheel(
              scrollController: _dayCtrl,
              itemCount: _dayCount,
              onSelectedItemChanged: (i) => setState(() => _day = i),
              labelBuilder: (i) => (i + 1).toString().padLeft(2, '0'),
            ),
          ),
          Expanded(
            flex: 4,
            child: YuztooCupertinoScrollWheel(
              scrollController: _monthCtrl,
              itemCount: 12,
              onSelectedItemChanged: _onMonthChanged,
              labelBuilder: (i) => _kMonthsFr[i],
            ),
          ),
          Expanded(
            flex: 3,
            child: YuztooCupertinoScrollWheel(
              scrollController: _yearCtrl,
              itemCount: _yearCount,
              onSelectedItemChanged: _onYearChanged,
              labelBuilder: (i) => (widget.minimum.year + i).toString(),
            ),
          ),
        ],
      ),
    );
  }
}
