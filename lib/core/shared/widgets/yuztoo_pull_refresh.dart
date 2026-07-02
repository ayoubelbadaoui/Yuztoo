import 'package:flutter/material.dart';

import '../constants/merchant_colors.dart';
import 'snackbar.dart';

/// Minimum wait between successful pull-to-refresh actions (anti-spam).
const Duration kPullRefreshMinInterval = Duration(seconds: 8);

/// Pull-to-refresh with Yuztoo styling and a cooldown between refreshes.
class YuztooPullRefresh extends StatefulWidget {
  const YuztooPullRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.minInterval = kPullRefreshMinInterval,
    this.displacement = 40,
    this.backgroundColor = MerchantColors.bgHeader,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Duration minInterval;
  final double displacement;
  final Color backgroundColor;

  @override
  State<YuztooPullRefresh> createState() => _YuztooPullRefreshState();
}

class _YuztooPullRefreshState extends State<YuztooPullRefresh> {
  DateTime? _lastRefreshAt;

  Future<void> _handleRefresh() async {
    final now = DateTime.now();
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < widget.minInterval) {
      if (mounted) {
        showRefreshThrottledSnackBar(context, widget.minInterval);
      }
      return;
    }
    _lastRefreshAt = now;
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: MerchantColors.gold,
      backgroundColor: widget.backgroundColor,
      displacement: widget.displacement,
      onRefresh: _handleRefresh,
      child: widget.child,
    );
  }
}

void showRefreshThrottledSnackBar(
  BuildContext context,
  Duration minInterval,
) {
  final seconds = minInterval.inSeconds;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Patientez ${seconds}s avant de réactualiser.',
          style: merchantSnackBarTextOnWarmAccent(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Makes empty / short content scrollable so pull-to-refresh always works.
Widget yuztooRefreshableEmpty(Widget child) {
  return CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    ),
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: child,
      ),
    ],
  );
}
