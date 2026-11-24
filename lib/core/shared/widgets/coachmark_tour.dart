import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/merchant_colors.dart';

/// One spotlighted step of a [CoachmarkTour].
class CoachmarkStep {
  const CoachmarkStep({
    required this.targetKey,
    required this.title,
    required this.message,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  /// Key on the real widget to spotlight (wrap it in a [KeyedSubtree]).
  final GlobalKey targetKey;
  final String title;
  final String message;
  final IconData icon;
}

/// Handle returned by [CoachmarkTour.show]; call [dismiss] from `dispose`.
class CoachmarkTourHandle {
  CoachmarkTourHandle._(this._entry);
  OverlayEntry? _entry;

  bool get isShowing => _entry != null;

  void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

/// Multi-step coachmark: dims the screen, cuts a pulsing gold spotlight around
/// each target in turn and shows a tooltip with « Suivant » / « Passer ».
///
/// Each step scrolls its target into view first, and the spotlight follows the
/// live position every frame (layout shifts, keyboard, late images).
class CoachmarkTour {
  const CoachmarkTour._();

  static CoachmarkTourHandle? show(
    BuildContext context, {
    required List<CoachmarkStep> steps,
    VoidCallback? onFinish,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    // Skip steps whose target is not on screen (hidden / empty sections).
    steps = steps.where((step) {
      final box = step.targetKey.currentContext?.findRenderObject();
      return box is RenderBox &&
          box.attached &&
          box.hasSize &&
          box.size.height > 1 &&
          box.size.width > 1;
    }).toList();
    if (overlay == null || steps.isEmpty) return null;
    FocusManager.instance.primaryFocus?.unfocus();

    late final CoachmarkTourHandle handle;
    final entry = OverlayEntry(
      builder: (_) => _CoachmarkTourOverlay(
        steps: steps,
        onClose: () {
          handle.dismiss();
          onFinish?.call();
        },
      ),
    );
    handle = CoachmarkTourHandle._(entry);
    overlay.insert(entry);
    return handle;
  }
}

class _CoachmarkTourOverlay extends StatefulWidget {
  const _CoachmarkTourOverlay({required this.steps, required this.onClose});

  final List<CoachmarkStep> steps;
  final VoidCallback onClose;

  @override
  State<_CoachmarkTourOverlay> createState() => _CoachmarkTourOverlayState();
}

class _CoachmarkTourOverlayState extends State<_CoachmarkTourOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _index = 0;
  Rect? _lastTarget;

  static const double _padding = 8;
  static const double _radius = 16;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _revealCurrent();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _revealCurrent() {
    final ctx = widget.steps[_index].targetKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.25,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onClose();
      return;
    }
    setState(() {
      _index++;
      _lastTarget = null;
    });
    _revealCurrent();
  }

  Rect? _measure() {
    final ctx = widget.steps[_index].targetKey.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => _buildFrame(context),
    );
  }

  Widget _buildFrame(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final step = widget.steps[_index];

    final target = _measure() ?? _lastTarget;
    _lastTarget = target;

    // Clamp tall targets to the visible area so the hole stays meaningful.
    final visible = Rect.fromLTRB(
      0,
      media.padding.top,
      screen.width,
      screen.height - media.padding.bottom,
    );
    final hole = target == null
        ? null
        : Rect.fromLTRB(
            target.left - _padding,
            target.top - _padding,
            target.right + _padding,
            target.bottom + _padding,
          ).intersect(visible);
    final validHole = hole != null && hole.width > 0 && hole.height > 0;

    const cardMargin = 16.0;
    const cardEstimate = 210.0;
    final spaceBelow =
        validHole ? visible.bottom - hole.bottom : visible.height;
    final spaceAbove = validHole ? hole.top - visible.top : 0.0;
    final placeBelow = spaceBelow >= cardEstimate || spaceBelow >= spaceAbove;
    final fits = spaceBelow >= cardEstimate || spaceAbove >= cardEstimate;

    double? top;
    double? bottom;
    if (!validHole || !fits) {
      bottom = media.padding.bottom + 24;
    } else if (placeBelow) {
      top = hole.bottom + 12;
    } else {
      bottom = screen.height - hole.top + 12;
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(
                painter: _TourSpotlightPainter(
                  hole: validHole ? hole : null,
                  radius: _radius,
                  pulse: _pulse.value,
                ),
              ),
            ),
          ),
          Positioned(
            left: cardMargin,
            right: cardMargin,
            top: top,
            bottom: bottom,
            child: _TourCard(
              step: step,
              index: _index,
              total: widget.steps.length,
              onNext: _next,
              onSkip: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final CoachmarkStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(step.icon, size: 18, color: MerchantColors.gold),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  step.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    height: 1.25,
                  ),
                ),
              ),
              Text(
                '${index + 1}/$total',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8A8A9A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.message,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              height: 1.45,
              color: const Color(0xFF4A4A5A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Progress dots.
              for (var i = 0; i < total; i++)
                Container(
                  width: i == index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: i == index
                        ? MerchantColors.gold
                        : MerchantColors.gold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const Spacer(),
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Passer',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF8A8A9A),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: MerchantColors.gold,
                  foregroundColor: MerchantColors.darkOverlay,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLast ? 'J’ai compris' : 'Suivant',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TourSpotlightPainter extends CustomPainter {
  _TourSpotlightPainter({
    required this.hole,
    required this.radius,
    required this.pulse,
  });

  final Rect? hole;
  final double radius;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.74);
    final h = hole;
    if (h == null) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(h, Radius.circular(radius));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rrect),
      ),
      scrim,
    );
    final grow = 3 + pulse * 8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(h.inflate(grow), Radius.circular(radius + grow)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = MerchantColors.gold.withValues(alpha: (1 - pulse) * 0.85),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = MerchantColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _TourSpotlightPainter old) =>
      old.pulse != pulse || old.hole != hole;
}
