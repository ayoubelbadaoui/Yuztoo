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

// ─── Palette ─────────────────────────────────────────────────────────────────

/// Sheet background — brand dark navy (matches the rest of the merchant
/// onboarding chrome). Reads warmer than pure black while keeping the
/// "luxe dark" feel.
const Color _kDarkSheetBackground = MerchantColors.bgMain;

/// Light-mode background — used in the storefront hours picker. Off-white
/// rather than pure white so the wheel doesn't glare against the rest of
/// the storefront UI.
const Color _kLightSheetBackground = Color(0xFFF8F6F0);

/// Dark-theme text colors.
const Color _kDarkTextSelected = Color(0xFFFFFFFF);
const Color _kDarkTextAdjacent = Color(0xCCFFFFFF); // 0.80
const Color _kDarkTextDistant = Color(0x73FFFFFF); // 0.45
const Color _kDarkCancelColor = Color(0x99FFFFFF); // 0.60 alpha white

/// Light-theme text colors.
const Color _kLightTextSelected = Color(0xFF1E293B);
const Color _kLightTextAdjacent = Color(0xCC1E293B); // 0.80
const Color _kLightTextDistant = Color(0x731E293B); // 0.45
const Color _kLightCancelColor = Color(0xFF64748B);

/// Confirm button is brand gold on both themes.
const Color _kConfirmColor = MerchantColors.gold;

/// 44pt toolbar height (iOS standard nav bar height).
const double _kToolbarHeight = 44.0;

Color _bgFor(bool light) =>
    light ? _kLightSheetBackground : _kDarkSheetBackground;
Color _titleColorFor(bool light) =>
    light ? _kLightTextSelected : _kDarkTextSelected;
Color _cancelColorFor(bool light) =>
    light ? _kLightCancelColor : _kDarkCancelColor;
Color _textSelectedFor(bool light) =>
    light ? _kLightTextSelected : _kDarkTextSelected;
Color _textAdjacentFor(bool light) =>
    light ? _kLightTextAdjacent : _kDarkTextAdjacent;
Color _textDistantFor(bool light) =>
    light ? _kLightTextDistant : _kDarkTextDistant;

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
    this.lightTheme = false,
    @Deprecated('Use lightTheme instead. backgroundColor is now derived from '
        'the theme to keep palettes consistent across pickers.')
    this.backgroundColor,
    @Deprecated('Selection band is no longer custom-drawn or auto-overlaid. '
        'Flag is retained as a no-op so legacy call sites compile.')
    this.showSelectionBand = true,
  });

  final Widget picker;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String? title;
  final String confirmLabel;
  final String cancelLabel;
  final bool lightTheme;
  // ignore: deprecated_member_use_from_same_package
  final Color? backgroundColor;
  // ignore: deprecated_member_use_from_same_package
  final bool showSelectionBand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bgFor(lightTheme),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              lightTheme: lightTheme,
            ),
            YuztooCupertinoWheelViewport(
              lightTheme: lightTheme,
              child: picker,
            ),
          ],
        ),
      ),
    );
  }
}

/// 44pt toolbar with grey "Annuler" / centered title / gold "Valider".
/// No bottom separator — the picker chrome is cleaner without the hairline
/// under the title; the wheel's own depth + the gold confirm button are
/// enough hierarchy.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.title,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    required this.lightTheme,
  });

  final String? title;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool lightTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kToolbarHeight,
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, _kToolbarHeight),
            onPressed: onCancel,
            child: Text(
              cancelLabel,
              style: GoogleFonts.outfit(
                color: _cancelColorFor(lightTheme),
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
                  color: _titleColorFor(lightTheme),
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

/// Fixed 216pt viewport. NO selection band — the wheel's 3D barrel
/// transform + three-stop text opacity is enough to lock the eye on the
/// center row. The previous gold band / hairline overlays were the
/// "rough" tell the user called out.
class YuztooCupertinoWheelViewport extends StatelessWidget {
  const YuztooCupertinoWheelViewport({
    super.key,
    required this.child,
    this.lightTheme = false,
    @Deprecated('Selection band is no longer drawn — flag is a no-op.')
    this.showSelectionBand = true,
  });

  final Widget child;
  final bool lightTheme;
  // ignore: deprecated_member_use_from_same_package
  final bool showSelectionBand;

  @override
  Widget build(BuildContext context) {
    final bg = _bgFor(lightTheme);
    return SizedBox(
      height: kCupertinoWheelHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Center(child: child)),
          // Top and bottom fades blend the wheel into the sheet chrome.
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
                      bg,
                      bg.withValues(alpha: 0.7),
                      bg.withValues(alpha: 0),
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
                      bg,
                      bg.withValues(alpha: 0.7),
                      bg.withValues(alpha: 0),
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
/// wheel reads with proper depth without relying on a colored highlight bar
/// or any hairlines. Fires a per-tick haptic on every row crossing to mimic
/// the iOS detent.
class YuztooCupertinoScrollWheel extends StatefulWidget {
  const YuztooCupertinoScrollWheel({
    super.key,
    required this.itemCount,
    required this.labelBuilder,
    required this.scrollController,
    required this.onSelectedItemChanged,
    this.looping = false,
    this.lightTheme = false,
  });

  final int itemCount;
  final String Function(int index) labelBuilder;
  final FixedExtentScrollController scrollController;
  final ValueChanged<int> onSelectedItemChanged;
  final bool looping;
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
        ? _textSelectedFor(widget.lightTheme)
        : distance == 1
            ? _textAdjacentFor(widget.lightTheme)
            : _textDistantFor(widget.lightTheme);
    return Center(
      child: Text(
        widget.labelBuilder(i),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 22,
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
    // NO selection overlay — keeps the wheel clean. The selected row is
    // still unambiguous because we render distance-based opacity and the
    // 3D barrel transform foreshortens off-center rows. Empty SizedBox
    // is required (the Cupertino default would otherwise draw hairlines).
    const selectionOverlay = SizedBox.shrink();
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
TextStyle yuztooWheelTextStyle({bool lightTheme = false}) => GoogleFonts.outfit(
      color: _textSelectedFor(lightTheme),
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
// so the rendered text matches our wheel: 22pt, regular weight, -0.2 letter
// spacing. Sizing matters because Cupertino's default is 21pt and looks
// small against our 22pt custom wheels.

const _kSystemPickerTextStyleDark = TextStyle(
  color: _kDarkTextSelected,
  fontSize: 22,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.2,
  height: 1.1,
);

const _kSystemPickerTextStyleLight = TextStyle(
  color: _kLightTextSelected,
  fontSize: 22,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.2,
  height: 1.1,
);

TextStyle _systemPickerTextStyleFor(bool light) =>
    light ? _kSystemPickerTextStyleLight : _kSystemPickerTextStyleDark;

/// Date + time wheel (merchant notifications schedule, etc.). Dark by
/// default — used inside onboarding and merchant tools.
Future<DateTime?> showYuztooCupertinoDateTimePicker({
  required BuildContext context,
  required DateTime initial,
  required DateTime minimumDate,
  required DateTime maximumDate,
  int minuteInterval = 1,
  String? title = 'Date et heure',
  bool lightTheme = false,
}) {
  var temp = initial;
  return _showPickerSheet<DateTime>(
    context: context,
    sheet: Builder(
      builder: (ctx) => YuztooCupertinoPickerSheet(
        title: title,
        lightTheme: lightTheme,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: lightTheme ? Brightness.light : Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: _systemPickerTextStyleFor(lightTheme),
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

/// Date-only wheel.
Future<DateTime?> showYuztooCupertinoDatePicker({
  required BuildContext context,
  required DateTime initial,
  required DateTime minimumDate,
  required DateTime maximumDate,
  String? title = 'Choisir une date',
  bool lightTheme = false,
}) {
  var temp = initial;
  return _showPickerSheet<DateTime>(
    context: context,
    sheet: Builder(
      builder: (ctx) => YuztooCupertinoPickerSheet(
        title: title,
        lightTheme: lightTheme,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: lightTheme ? Brightness.light : Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: _systemPickerTextStyleFor(lightTheme),
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

/// Time-only wheel — LIGHT theme by default because the storefront hours
/// picker (its primary caller) sits on the light storefront chrome. Callers
/// inside the dark onboarding flow pass `lightTheme: false` to opt into
/// the brand dark navy variant.
Future<DateTime?> showYuztooCupertinoTimePicker({
  required BuildContext context,
  required DateTime initial,
  int minuteInterval = 5,
  String? title = 'Choisir l\'heure',
  bool lightTheme = true,
}) {
  var temp = initial;
  return _showPickerSheet<DateTime>(
    context: context,
    sheet: Builder(
      builder: (ctx) => YuztooCupertinoPickerSheet(
        title: title,
        lightTheme: lightTheme,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: lightTheme ? Brightness.light : Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: _systemPickerTextStyleFor(lightTheme),
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
