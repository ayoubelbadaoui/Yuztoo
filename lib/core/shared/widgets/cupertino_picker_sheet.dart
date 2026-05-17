import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/merchant_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dark iPhone-native wheel picker.
//
// Visual contract (matches iOS 17 Date & Time wheel):
//   - Near-black background (`#0F1419`), 20pt top-rounded sheet.
//   - 44pt toolbar: grey "Annuler" / centered title / gold "Valider".
//   - Wheel: 216pt tall, 5–6 rows visible, items rendered uniformly in
//     SF-like sans-serif. NO custom selection band — Cupertino's native
//     `CupertinoPickerDefaultSelectionOverlay` paints the two grey hairlines
//     that Apple uses on every system wheel.
//   - Selected row at full white; adjacent rows ~0.78 alpha; distant ~0.45.
//   - No magnification gimmick — the 3D barrel curvature alone makes the
//     selected row pop. Magnification > 1.0 reads as "comic" and was the
//     biggest "rough" tell of the previous iteration.
//
// Tactile contract:
//   - Per-tick `HapticFeedback.selectionClick()` on every row crossing.
//     iOS native pickers detent on every row — flutter's
//     `CupertinoPicker` emits this on iOS automatically, but not on
//     Android, so we fire it explicitly to keep the feel consistent.
// ─────────────────────────────────────────────────────────────────────────────

/// Matches Apple's wheel height (216pt). Do not stretch in [Expanded].
const double kCupertinoWheelHeight = 216.0;

/// 32pt row extent — Apple's default. Smaller than the previous 40pt
/// experiment, which crowded the wheel and reduced visible-row count.
const double kCupertinoWheelItemExtent = 32.0;

/// iOS-native wheel parameters. Values match `CupertinoPicker`'s defaults:
///   - 1.07 diameter ratio: subtle barrel curvature, not a drum.
///   - 1.45 squeeze: loose spacing so 5+ rows are comfortably visible.
///   - 1.0 magnification: NO size jump on the selected row.
const double _kWheelDiameterRatio = 1.07;
const double _kWheelSqueeze = 1.45;
const double _kWheelMagnification = 1.0;

// ─── iPhone-native palette ────────────────────────────────────────────────────

/// Sheet background — Apple uses pure black with material blur underneath,
/// but on Yuztoo's solid backgrounds an off-black reads warmer / less harsh
/// than `#000000`. Slightly tinted toward the brand navy.
const Color _kSheetBackground = Color(0xFF0F1419);

/// Selected-row text — pure white for crispness.
const Color _kTextSelected = Color(0xFFFFFFFF);

/// Off-selection text — Apple uses `secondaryLabel` (~0.6 alpha white in
/// dark mode). We use two opacity steps so the wheel reads with proper
/// 3D depth.
const Color _kTextAdjacent = Color(0xCCFFFFFF); // 0.80
const Color _kTextDistant = Color(0x73FFFFFF); // 0.45

/// Toolbar text colors. Cancel is muted; confirm is the brand gold.
const Color _kCancelColor = Color(0x99FFFFFF); // 0.60 alpha white
const Color _kConfirmColor = MerchantColors.gold;
const Color _kTitleColor = Color(0xFFFFFFFF);

/// Toolbar bottom separator — Apple uses a hairline in `separatorColor`.
const Color _kToolbarSeparator = Color(0x33FFFFFF); // 0.20 alpha white

/// 44pt toolbar height (iOS standard nav bar height).
const double _kToolbarHeight = 44.0;

// ─────────────────────────────────────────────────────────────────────────────

/// Bottom sheet with toolbar + fixed-height, centered wheel.
class YuztooCupertinoPickerSheet extends StatelessWidget {
  const YuztooCupertinoPickerSheet({
    super.key,
    required this.picker,
    required this.onCancel,
    required this.onConfirm,
    this.title,
    this.confirmLabel = 'Valider',
    this.cancelLabel = 'Annuler',
    @Deprecated('Use the default dark theme. Background and lightTheme are '
        'retained as no-ops for legacy call sites.')
    this.backgroundColor = _kSheetBackground,
    @Deprecated('Selection band is no longer custom-drawn — the iOS default '
        'overlay renders the two grey hairlines. Flag is retained as a no-op.')
    this.showSelectionBand = true,
    @Deprecated('Light theme is no longer supported — all pickers use the '
        'dark iPhone-native palette. Flag is retained as a no-op.')
    this.lightTheme = false,
  });

  final Widget picker;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String? title;
  final String confirmLabel;
  final String cancelLabel;
  // ignore: deprecated_member_use_from_same_package
  final Color backgroundColor;
  // ignore: deprecated_member_use_from_same_package
  final bool showSelectionBand;
  // ignore: deprecated_member_use_from_same_package
  final bool lightTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _kSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Toolbar(
              title: title,
              cancelLabel: cancelLabel,
              confirmLabel: confirmLabel,
              onCancel: onCancel,
              onConfirm: onConfirm,
            ),
            YuztooCupertinoWheelViewport(child: picker),
          ],
        ),
      ),
    );
  }
}

/// 44pt toolbar with grey "Annuler" / centered title / gold "Valider".
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.title,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  final String? title;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kToolbarHeight,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _kToolbarSeparator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, _kToolbarHeight),
            onPressed: onCancel,
            child: Text(
              cancelLabel,
              style: GoogleFonts.outfit(
                color: _kCancelColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (title != null)
            Expanded(
              child: Text(
                title!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: _kTitleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            )
          else
            const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, _kToolbarHeight),
            onPressed: () {
              HapticFeedback.selectionClick();
              onConfirm();
            },
            child: Text(
              confirmLabel,
              style: GoogleFonts.outfit(
                color: _kConfirmColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed 216pt viewport. The selection slot is drawn by Cupertino's default
/// overlay (two grey hairlines), so we add nothing on top — that's the iOS
/// look. Subtle edge fades blend the wheel into the sheet chrome.
class YuztooCupertinoWheelViewport extends StatelessWidget {
  const YuztooCupertinoWheelViewport({
    super.key,
    required this.child,
    @Deprecated('Selection band is now the iOS default overlay (hairlines). '
        'This flag is a no-op and retained for legacy call sites.')
    this.showSelectionBand = true,
    @Deprecated('Light theme is no longer supported — see picker sheet.')
    this.lightTheme = false,
  });

  final Widget child;
  // ignore: deprecated_member_use_from_same_package
  final bool showSelectionBand;
  // ignore: deprecated_member_use_from_same_package
  final bool lightTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kCupertinoWheelHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Center(child: child)),
          // Top and bottom fades blend the wheel into the sheet chrome.
          // Three-stop gradient (full → faint → none) gives a smoother
          // fall-off than a linear two-stop and never looks "cut".
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kSheetBackground,
                      _kSheetBackground.withValues(alpha: 0.7),
                      _kSheetBackground.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _kSheetBackground,
                      _kSheetBackground.withValues(alpha: 0.7),
                      _kSheetBackground.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single centered scroll column — use inside [Row] with [Expanded] for balance.
///
/// Renders in three opacity stops (selected / adjacent / distant) so the
/// wheel reads with proper depth without relying on a colored highlight bar.
/// Fires a per-tick haptic on every row crossing to mimic the iOS detent.
class YuztooCupertinoScrollWheel extends StatefulWidget {
  const YuztooCupertinoScrollWheel({
    super.key,
    required this.itemCount,
    required this.labelBuilder,
    required this.scrollController,
    required this.onSelectedItemChanged,
    this.looping = false,
    @Deprecated('Light theme is no longer supported.')
    this.lightTheme = false,
  });

  final int itemCount;
  final String Function(int index) labelBuilder;
  final FixedExtentScrollController scrollController;
  final ValueChanged<int> onSelectedItemChanged;
  final bool looping;
  // ignore: deprecated_member_use_from_same_package
  final bool lightTheme;

  @override
  State<YuztooCupertinoScrollWheel> createState() =>
      _YuztooCupertinoScrollWheelState();
}

class _YuztooCupertinoScrollWheelState
    extends State<YuztooCupertinoScrollWheel> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.scrollController.initialItem;
  }

  void _handleSelectionChanged(int index) {
    HapticFeedback.selectionClick();
    if (index != _selected) {
      setState(() => _selected = index);
    }
    widget.onSelectedItemChanged(index);
  }

  Widget _buildItem(int i) {
    final distance = (i - _selected).abs();
    final color = distance == 0
        ? _kTextSelected
        : distance == 1
            ? _kTextAdjacent
            : _kTextDistant;
    return Center(
      child: Text(
        widget.labelBuilder(i),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 22,
          // iOS uses uniform weight across the wheel — depth comes from the
          // 3D barrel transform, not weight contrast. The previous w700/w500
          // contrast was the "comic" tell.
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
          height: 1.1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Cupertino's native selection overlay — paints the two grey
    // hairlines bracketing the selection slot. This is THE iOS look and
    // the previous custom gold band was the most off-key element of the
    // earlier iteration.
    const selectionOverlay = CupertinoPickerDefaultSelectionOverlay();
    if (widget.looping) {
      return CupertinoPicker(
        scrollController: widget.scrollController,
        itemExtent: kCupertinoWheelItemExtent,
        diameterRatio: _kWheelDiameterRatio,
        squeeze: _kWheelSqueeze,
        magnification: _kWheelMagnification,
        useMagnifier: false,
        looping: true,
        backgroundColor: Colors.transparent,
        selectionOverlay: selectionOverlay,
        onSelectedItemChanged: _handleSelectionChanged,
        children: List<Widget>.generate(widget.itemCount, _buildItem),
      );
    }
    return CupertinoPicker.builder(
      scrollController: widget.scrollController,
      itemExtent: kCupertinoWheelItemExtent,
      diameterRatio: _kWheelDiameterRatio,
      squeeze: _kWheelSqueeze,
      magnification: _kWheelMagnification,
      useMagnifier: false,
      backgroundColor: Colors.transparent,
      selectionOverlay: selectionOverlay,
      onSelectedItemChanged: _handleSelectionChanged,
      childCount: widget.itemCount,
      itemBuilder: (context, i) => _buildItem(i),
    );
  }
}

/// Default text style for wheel items — exposed for consumers that compute
/// layout (intrinsic widths) outside of the wheel itself.
TextStyle yuztooWheelTextStyle({
  @Deprecated('Light theme is no longer supported.') bool lightTheme = false,
}) =>
    GoogleFonts.outfit(
      color: _kTextSelected,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
      height: 1.1,
    );

Future<T?> _showPickerSheet<T>({
  required BuildContext context,
  required Widget sheet,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => sheet,
  );
}

// ── CupertinoDatePicker theming ──────────────────────────────────────────────
//
// The system `CupertinoDatePicker` (used for date+time, date-only, time-only
// wheels) has its own internal text style. We wrap it in a `CupertinoTheme`
// so the rendered text matches our wheel: white, 22pt, regular weight,
// -0.2 letter spacing. Sizing matters because Cupertino's default is 21pt
// and looks small against our 22pt custom wheels.

const _kSystemPickerTextStyle = TextStyle(
  color: _kTextSelected,
  fontSize: 22,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.2,
  height: 1.1,
);

/// Dark-themed date + time wheel (merchant notifications schedule, etc.).
Future<DateTime?> showYuztooCupertinoDateTimePicker({
  required BuildContext context,
  required DateTime initial,
  required DateTime minimumDate,
  required DateTime maximumDate,
  int minuteInterval = 1,
  String? title = 'Date et heure',
}) {
  var temp = initial;
  return _showPickerSheet<DateTime>(
    context: context,
    sheet: Builder(
      builder: (ctx) => YuztooCupertinoPickerSheet(
        title: title,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: _kSystemPickerTextStyle,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: kCupertinoWheelHeight,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              use24hFormat: true,
              minuteInterval: minuteInterval,
              initialDateTime: initial,
              minimumDate: minimumDate,
              maximumDate: maximumDate,
              onDateTimeChanged: (d) {
                HapticFeedback.selectionClick();
                temp = d;
              },
            ),
          ),
        ),
      ),
    ),
  );
}

/// Dark-themed date-only wheel.
Future<DateTime?> showYuztooCupertinoDatePicker({
  required BuildContext context,
  required DateTime initial,
  required DateTime minimumDate,
  required DateTime maximumDate,
  String? title = 'Choisir une date',
}) {
  var temp = initial;
  return _showPickerSheet<DateTime>(
    context: context,
    sheet: Builder(
      builder: (ctx) => YuztooCupertinoPickerSheet(
        title: title,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: _kSystemPickerTextStyle,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: kCupertinoWheelHeight,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initial,
              minimumDate: minimumDate,
              maximumDate: maximumDate,
              onDateTimeChanged: (d) {
                HapticFeedback.selectionClick();
                temp = d;
              },
            ),
          ),
        ),
      ),
    ),
  );
}

/// Time-only wheel (storefront hours). Same dark palette as the others —
/// the light theme variant was removed when the picker chrome unified on
/// the iPhone-dark aesthetic.
Future<DateTime?> showYuztooCupertinoTimePicker({
  required BuildContext context,
  required DateTime initial,
  int minuteInterval = 5,
  String? title = 'Choisir l\'heure',
}) {
  var temp = initial;
  return _showPickerSheet<DateTime>(
    context: context,
    sheet: Builder(
      builder: (ctx) => YuztooCupertinoPickerSheet(
        title: title,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: _kSystemPickerTextStyle,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: kCupertinoWheelHeight,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              minuteInterval: minuteInterval,
              initialDateTime: initial,
              onDateTimeChanged: (d) {
                HapticFeedback.selectionClick();
                temp = d;
              },
            ),
          ),
        ),
      ),
    ),
  );
}
