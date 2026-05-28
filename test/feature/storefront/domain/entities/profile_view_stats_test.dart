import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/storefront/domain/entities/profile_view_stats.dart';

void main() {
  group('ProfileViewStats.weeklyChangePercent', () {
    test('returns 0 when both windows are empty', () {
      const stats = ProfileViewStats(weeklyViews: 0, previousWeeklyViews: 0);
      expect(stats.weeklyChangePercent, 0);
    });

    test('returns +100 when prior window is empty but current is not', () {
      const stats = ProfileViewStats(weeklyViews: 12, previousWeeklyViews: 0);
      // Capped to +100 to avoid divide-by-zero / "+∞%" headlines.
      expect(stats.weeklyChangePercent, 100);
    });

    test('returns negative pct when current window shrank', () {
      const stats = ProfileViewStats(weeklyViews: 4, previousWeeklyViews: 8);
      expect(stats.weeklyChangePercent, -50);
    });

    test('returns positive pct when current window grew', () {
      const stats = ProfileViewStats(weeklyViews: 9, previousWeeklyViews: 6);
      expect(stats.weeklyChangePercent, closeTo(50, 0.001));
    });

    test('returns 0 pct when windows are equal and non-zero', () {
      const stats = ProfileViewStats(weeklyViews: 7, previousWeeklyViews: 7);
      expect(stats.weeklyChangePercent, 0);
    });
  });

  test('ProfileViewStats.empty exposes zeros', () {
    expect(ProfileViewStats.empty.weeklyViews, 0);
    expect(ProfileViewStats.empty.previousWeeklyViews, 0);
    expect(ProfileViewStats.empty.weeklyChangePercent, 0);
  });
}
