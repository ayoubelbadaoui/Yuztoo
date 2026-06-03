/// Aggregated profile-view metrics for a merchant's storefront, computed
/// over a 7-day sliding window with comparison vs. the prior 7-day window.
///
/// Pure-domain value object — no Flutter / Firebase / Riverpod imports so
/// it can be exercised by unit tests and reused across layers.
class ProfileViewStats {
  const ProfileViewStats({
    required this.weeklyViews,
    required this.previousWeeklyViews,
  });

  /// Distinct (viewer, day) pairs over the last 7 days, anchored on UTC.
  final int weeklyViews;

  /// Same metric for the prior 7 days (days [now-13, now-7] inclusive),
  /// used to compute [weeklyChangePercent].
  final int previousWeeklyViews;

  /// Empty stats — surfaced when nobody has viewed yet, OR when the read
  /// fails. Best-effort: analytics must never crash the dashboard.
  static const ProfileViewStats empty = ProfileViewStats(
    weeklyViews: 0,
    previousWeeklyViews: 0,
  );

  /// Percentage change vs. the prior 7-day window.
  ///
  /// Edge cases (deliberately defensive — the dashboard renders this
  /// number prominently and "+∞%" or NaN would look broken):
  /// * Both windows empty → 0 (UI shows "0", no badge meaning).
  /// * Prior empty, current > 0 → +100 (cap "from nothing" growth so
  ///   we don't divide by zero or show absurd headlines like "+∞%").
  /// * Otherwise → standard `(now - prev) / prev * 100`.
  double get weeklyChangePercent {
    if (previousWeeklyViews == 0) {
      return weeklyViews == 0 ? 0 : 100;
    }
    return ((weeklyViews - previousWeeklyViews) / previousWeeklyViews) * 100;
  }
}
