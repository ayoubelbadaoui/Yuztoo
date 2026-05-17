import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/merchant_colors.dart';

/// Matches [CupertinoDatePicker] intrinsic height — do not stretch in [Expanded].
const double kCupertinoWheelHeight = 224.0;

/// Default row height for [CupertinoPicker] columns (aligned with iOS wheels).
const double kCupertinoWheelItemExtent = 40.0;

/// Wheel physics tuned for a soft, luxe iOS-style feel:
///   - higher diameter ratio → deeper curvature, more "drum"-like depth.
///   - tight squeeze → adjacent rows compress, drawing the eye to the center.
///   - subtle magnification → selected row pops without looking comic.
const double _kWheelDiameterRatio = 1.6;
const double _kWheelSqueeze = 0.92;
const double _kWheelMagnification = 1.12;

/// Bottom sheet with toolbar + fixed-height, centered wheel (no vertical stretch).
class YuztooCupertinoPickerSheet extends StatelessWidget {
  const YuztooCupertinoPickerSheet({
    super.key,
    required this.picker,
    required this.onCancel,
    required this.onConfirm,
    this.title,
    this.confirmLabel = 'Valider',
    this.cancelLabel = 'Annuler',
    this.backgroundColor = MerchantColors.bgHeader,
    this.showSelectionBand = true,
    this.lightTheme = false,
  });

  final Widget picker;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String? title;
  final String confirmLabel;
  final String cancelLabel;
  final Color backgroundColor;
  final bool showSelectionBand;
  final bool lightTheme;

  @override
  Widget build(BuildContext context) {
    final cancelColor = lightTheme
        ? const Color(0xFF64748B)
        : MerchantColors.textGrey;
    final confirmColor =
        lightTheme ? const Color(0xFFD4A017) : MerchantColors.gold;
    final titleColor =
        lightTheme ? const Color(0xFF1E293B) : MerchantColors.textWhite;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: (lightTheme ? Colors.black : Colors.white)
                        .withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: onCancel,
                    child: Text(
                      cancelLabel,
                      style: GoogleFonts.outfit(
                        color: cancelColor,
                        fontSize: 15,
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
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onConfirm();
                    },
                    child: Text(
                      confirmLabel,
                      style: GoogleFonts.outfit(
                        color: confirmColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            YuztooCupertinoWheelViewport(
              showSelectionBand: showSelectionBand,
              lightTheme: lightTheme,
              child: picker,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed 216pt viewport: centers the wheel, gold selection band, edge fades.
class YuztooCupertinoWheelViewport extends StatelessWidget {
  const YuztooCupertinoWheelViewport({
    super.key,
    required this.child,
    this.showSelectionBand = true,
    this.lightTheme = false,
  });

  final Widget child;
  final bool showSelectionBand;
  final bool lightTheme;

  @override
  Widget build(BuildContext context) {
    final bandColor =
        lightTheme ? const Color(0xFFD4A017) : MerchantColors.gold;
    final fadeColor = lightTheme
        ? const Color(0xFFF8F6F0)
        : MerchantColors.bgHeader;

    return SizedBox(
      height: kCupertinoWheelHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(child: child),
          ),
          if (showSelectionBand)
            Positioned(
              left: 16,
              right: 16,
              child: Container(
                height: kCupertinoWheelItemExtent,
                decoration: BoxDecoration(
                  // Soft gold sheen: brightest at center, fading toward the
                  // edges. Reads as a polished metallic band rather than a
                  // flat highlight rectangle — feels less plastic.
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      bandColor.withValues(alpha: 0),
                      bandColor.withValues(alpha: lightTheme ? 0.14 : 0.13),
                      bandColor.withValues(alpha: lightTheme ? 0.14 : 0.13),
                      bandColor.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.18, 0.82, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      // Hairline — bold border was the previous "rough"
                      // look. 0.6px reads as a subtle separator on Retina.
                      color: bandColor.withValues(alpha: 0.38),
                      width: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          // Top fade: multi-stop gradient (full → faint → none) so adjacent
          // rows are still readable but recede smoothly into the chrome.
          // The previous two-stop fade was visibly linear and made wheels
          // look "cut off".
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 72,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      fadeColor,
                      fadeColor.withValues(alpha: 0.86),
                      fadeColor.withValues(alpha: 0.3),
                      fadeColor.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.4, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 72,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      fadeColor,
                      fadeColor.withValues(alpha: 0.86),
                      fadeColor.withValues(alpha: 0.3),
                      fadeColor.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.4, 0.8, 1.0],
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
/// Tactile contract:
///   - emits [HapticFeedback.selectionClick] on every wheel tick, matching
///     iOS native pickers. Without this the wheel feels mechanical; with it
///     it feels like a physical wheel detenting under your thumb.
///   - the currently-selected item is rendered with extra weight and a
///     slight gold tint so the eye locks onto the band without needing to
///     squint at the highlight bar.
///   - off-selection items fade subtly toward the edges of the viewport,
///     emphasizing the center and hiding the abrupt edge cutoff.
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
    // Selection-tick haptic on every item crossing. This is the single
    // biggest "luxe feel" upgrade for an iOS-style wheel — native pickers
    // detent on each row and users perceive a silent wheel as buggy.
    HapticFeedback.selectionClick();
    if (index != _selected) {
      setState(() => _selected = index);
    }
    widget.onSelectedItemChanged(index);
  }

  Widget _buildItem(int i) {
    final distance = (i - _selected).abs();
    final style = _wheelItemStyle(
      lightTheme: widget.lightTheme,
      distanceFromSelected: distance,
    );
    return Center(
      child: Text(
        widget.labelBuilder(i),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const selectionOverlay = CupertinoPickerDefaultSelectionOverlay(
      background: Colors.transparent,
    );
    // .builder doesn't accept `looping`, so when looping is requested fall
    // back to the static constructor (which materialises all rows up-front).
    if (widget.looping) {
      return CupertinoPicker(
        scrollController: widget.scrollController,
        itemExtent: kCupertinoWheelItemExtent,
        diameterRatio: _kWheelDiameterRatio,
        squeeze: _kWheelSqueeze,
        magnification: _kWheelMagnification,
        useMagnifier: true,
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
      useMagnifier: true,
      backgroundColor: Colors.transparent,
      selectionOverlay: selectionOverlay,
      onSelectedItemChanged: _handleSelectionChanged,
      childCount: widget.itemCount,
      itemBuilder: (context, i) => _buildItem(i),
    );
  }
}

/// Returns the text style for a wheel item, varying weight + tint by distance
/// from the selected row. Centered items lock the eye; adjacent rows fade
/// toward the viewport edge — produces the iOS-native "selected row pops"
/// effect without an opaque band.
TextStyle _wheelItemStyle({
  required bool lightTheme,
  required int distanceFromSelected,
}) {
  final isSelected = distanceFromSelected == 0;
  final isAdjacent = distanceFromSelected == 1;
  final baseColor = lightTheme ? const Color(0xFF1E293B) : Colors.white;
  final selectedColor =
      lightTheme ? const Color(0xFF1E293B) : Colors.white;
  final color = isSelected
      ? selectedColor
      : baseColor.withValues(
          alpha: isAdjacent ? 0.78 : 0.52,
        );
  return GoogleFonts.outfit(
    color: color,
    fontSize: 20,
    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
    letterSpacing: isSelected ? 0.1 : 0,
    height: 1.1,
  );
}

/// Default text style for wheel items — exposed for consumers that need
/// to compute layout (intrinsic widths) outside of the wheel itself.
TextStyle yuztooWheelTextStyle({bool lightTheme = false}) => GoogleFonts.outfit(
      color: lightTheme ? const Color(0xFF1E293B) : Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w500,
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
        showSelectionBand: false,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 21,
              ),
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
              onDateTimeChanged: (d) => temp = d,
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
        showSelectionBand: false,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 21,
              ),
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
              onDateTimeChanged: (d) => temp = d,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Light-themed time wheel (storefront hours).
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
        lightTheme: true,
        backgroundColor: const Color(0xFFF8F6F0),
        showSelectionBand: false,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(temp),
        picker: CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.light,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 22,
              ),
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
              onDateTimeChanged: (d) => temp = d,
            ),
          ),
        ),
      ),
    ),
  );
}
