import 'package:flutter/material.dart';

/// Shows [text] normally when it fits. When a line is too wide for the slot,
/// that line scrolls **horizontally** (right → left) with pauses — never
/// vertical scrolling. Used on compact onboarding cards.
class OverflowScrollText extends StatelessWidget {
  const OverflowScrollText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 2,
    this.textAlign = TextAlign.start,
    this.pauseDuration = const Duration(milliseconds: 1800),
    this.scrollDuration = const Duration(milliseconds: 3200),
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;
  final Duration pauseDuration;
  final Duration scrollDuration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0 || text.isEmpty) {
          return Text(text, style: style, textAlign: textAlign);
        }

        final direction = Directionality.of(context);
        final lines = _wrapLines(
          text: text,
          style: style,
          maxWidth: maxWidth,
          direction: direction,
        );

        if (lines.isEmpty) {
          return Text(text, style: style, textAlign: textAlign);
        }

        final fitsInMaxLines = lines.length <= maxLines;
        final allLinesFitWidth = lines.every((line) {
          final w = _lineWidth(line, style, direction);
          return w <= maxWidth + 0.5;
        });

        if (fitsInMaxLines && allLinesFitWidth) {
          return Text(
            text,
            style: style,
            maxLines: maxLines,
            textAlign: textAlign,
          );
        }

        return Column(
          crossAxisAlignment: _columnAlign(textAlign),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              _HorizontalMarqueeLine(
                text: line,
                style: style,
                maxWidth: maxWidth,
                textAlign: textAlign,
                pauseDuration: pauseDuration,
                scrollDuration: scrollDuration,
              ),
          ],
        );
      },
    );
  }

  CrossAxisAlignment _columnAlign(TextAlign align) {
    return switch (align) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.end || TextAlign.right => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
  }
}

List<String> _wrapLines({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required TextDirection direction,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
  )..layout(maxWidth: maxWidth);

  final result = <String>[];
  for (final metric in painter.computeLineMetrics()) {
    final y = metric.baseline - metric.ascent;
    final start = painter.getPositionForOffset(Offset(0, y)).offset;
    final end = painter
        .getPositionForOffset(Offset(metric.width, y))
        .offset
        .clamp(start, text.length);
    result.add(text.substring(start, end).trimRight());
  }
  return result;
}

double _lineWidth(String line, TextStyle style, TextDirection direction) {
  final painter = TextPainter(
    text: TextSpan(text: line, style: style),
    textDirection: direction,
    maxLines: 1,
  )..layout();
  return painter.width;
}

class _HorizontalMarqueeLine extends StatefulWidget {
  const _HorizontalMarqueeLine({
    required this.text,
    required this.style,
    required this.maxWidth,
    required this.textAlign,
    required this.pauseDuration,
    required this.scrollDuration,
  });

  final String text;
  final TextStyle style;
  final double maxWidth;
  final TextAlign textAlign;
  final Duration pauseDuration;
  final Duration scrollDuration;

  @override
  State<_HorizontalMarqueeLine> createState() => _HorizontalMarqueeLineState();
}

class _HorizontalMarqueeLineState extends State<_HorizontalMarqueeLine>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scrollAnimation;
  double _overflow = 0;
  bool _marquee = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  @override
  void didUpdateWidget(covariant _HorizontalMarqueeLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.maxWidth != widget.maxWidth ||
        oldWidget.style != widget.style) {
      _controller?.dispose();
      _controller = null;
      _scrollAnimation = null;
      _marquee = false;
      _overflow = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
    }
  }

  void _setup() {
    if (!mounted) return;
    final direction = Directionality.of(context);
    final lineWidth = _lineWidth(widget.text, widget.style, direction);
    final needsMarquee = lineWidth > widget.maxWidth + 0.5;

    if (!needsMarquee) {
      if (_marquee) {
        setState(() {
          _marquee = false;
          _overflow = 0;
        });
      }
      return;
    }

    _overflow = lineWidth - widget.maxWidth;
    final pauseMs = widget.pauseDuration.inMilliseconds;
    final scrollMs = widget.scrollDuration.inMilliseconds;
    final totalMs = pauseMs + scrollMs + pauseMs + scrollMs;

    _controller?.dispose();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _scrollAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: pauseMs.toDouble()),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: scrollMs.toDouble(),
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: pauseMs.toDouble()),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: scrollMs.toDouble(),
      ),
    ]).animate(_controller!);

    _controller!.repeat();
    setState(() => _marquee = true);
  }

  @override
  Widget build(BuildContext context) {
    final height = (widget.style.fontSize ?? 14) * (widget.style.height ?? 1.2);

    if (!_marquee || _controller == null || _scrollAnimation == null) {
      return SizedBox(
        width: widget.maxWidth,
        height: height,
        child: Align(
          alignment: _align(widget.textAlign),
          child: Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            textAlign: widget.textAlign,
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.maxWidth,
      height: height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _scrollAnimation!,
          builder: (context, child) {
            // Right → left: content translates leftward to reveal the end.
            final dx = _scrollAnimation!.value * _overflow;
            return Transform.translate(
              offset: Offset(-dx, 0),
              child: child,
            );
          },
          child: Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  Alignment _align(TextAlign align) {
    return switch (align) {
      TextAlign.center => Alignment.center,
      TextAlign.end || TextAlign.right => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }
}
