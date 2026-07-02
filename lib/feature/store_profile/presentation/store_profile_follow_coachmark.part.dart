part of 'store_profile_screen.dart';

/// Full-screen coachmark that dims the storefront and spotlights the real
/// "Suivre ce commerce" CTA. Shown by the scan / NFC funnel for logged-in
/// non-followers so they understand that following is what registers the
/// passage. Tapping the spotlit button (or the card hint) follows and chains
/// straight into the fidélité flow — no second scan.
class _FollowPassageCoachmark extends StatefulWidget {
  const _FollowPassageCoachmark({
    required this.targetRect,
    required this.title,
    required this.message,
    required this.ctaHint,
    required this.onTargetTap,
    required this.onDismiss,
  });

  final Rect targetRect;
  final String title;
  final String message;
  final String ctaHint;
  final VoidCallback onTargetTap;
  final VoidCallback onDismiss;

  @override
  State<_FollowPassageCoachmark> createState() =>
      _FollowPassageCoachmarkState();
}

class _FollowPassageCoachmarkState extends State<_FollowPassageCoachmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const double _spotlightPadding = 8;
  static const double _spotlightRadius = 18;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;

    final hole = Rect.fromLTRB(
      widget.targetRect.left - _spotlightPadding,
      widget.targetRect.top - _spotlightPadding,
      widget.targetRect.right + _spotlightPadding,
      widget.targetRect.bottom + _spotlightPadding,
    );

    // Prefer the tooltip below the CTA; flip above when there isn't room.
    final bool below =
        hole.bottom + 190 < screen.height - media.padding.bottom;
    const double cardMargin = 20;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dimmed scrim with a rounded cut-out around the CTA. Pulsing ring.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => CustomPaint(
                  painter: _SpotlightPainter(
                    hole: hole,
                    radius: _spotlightRadius,
                    pulse: _pulse.value,
                  ),
                ),
              ),
            ),
          ),
          // Transparent hot-zone over the real button → follow + continue.
          Positioned(
            left: hole.left,
            top: hole.top,
            width: hole.width,
            height: hole.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTargetTap,
              child: const SizedBox.expand(),
            ),
          ),
          // Tooltip card with an arrow pointing at the CTA.
          Positioned(
            left: cardMargin,
            width: screen.width - cardMargin * 2,
            top: below ? hole.bottom + 14 : null,
            bottom: below ? null : screen.height - hole.top + 14,
            child: _Tooltip(
              below: below,
              arrowLeft: (hole.center.dx - cardMargin - 11)
                  .clamp(14.0, screen.width - cardMargin * 2 - 36),
              title: widget.title,
              message: widget.message,
              ctaHint: widget.ctaHint,
              onCta: widget.onTargetTap,
              onDismiss: widget.onDismiss,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.below,
    required this.arrowLeft,
    required this.title,
    required this.message,
    required this.ctaHint,
    required this.onCta,
    required this.onDismiss,
  });

  final bool below;
  final double arrowLeft;
  final String title;
  final String message;
  final String ctaHint;
  final VoidCallback onCta;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final arrow = Padding(
      padding: EdgeInsets.only(left: arrowLeft),
      child: CustomPaint(
        size: const Size(22, 10),
        painter: _TooltipArrowPainter(pointingUp: below),
      ),
    );

    final card = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: StorefrontColors.primaryGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 17,
                  color: StorefrontColors.primaryGold,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: StorefrontColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              height: 1.45,
              color: StorefrontColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 18,
                color: StorefrontColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ctaHint,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: StorefrontColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    'Plus tard',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: StorefrontColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final children = below ? <Widget>[arrow, card] : <Widget>[card, arrow];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// Paints the dim scrim with a rounded-rectangle hole around the CTA plus a
/// gold border and an outward pulsing ring to draw the eye.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.pulse,
  });

  final Rect hole;
  final double radius;
  final double pulse; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.72);
    final holeRRect =
        RRect.fromRectAndRadius(hole, Radius.circular(radius));
    final cutout = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(holeRRect),
    );
    canvas.drawPath(cutout, scrim);

    final grow = 4 + pulse * 10;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = StorefrontColors.primaryGold.withValues(
        alpha: (1 - pulse) * 0.85,
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        hole.inflate(grow),
        Radius.circular(radius + grow),
      ),
      ring,
    );

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = StorefrontColors.primaryGold;
    canvas.drawRRect(holeRRect, border);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.pulse != pulse || old.hole != hole || old.radius != radius;
}

class _TooltipArrowPainter extends CustomPainter {
  _TooltipArrowPainter({required this.pointingUp});

  final bool pointingUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    if (pointingUp) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipArrowPainter old) =>
      old.pointingUp != pointingUp;
}
