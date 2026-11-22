import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/yuztoo_news/domain/entities/yuztoo_news.dart';

YuztooNews _news(
  String id,
  DateTime publishOn, {
  YuztooNewsReleaseStatus releaseStatus = YuztooNewsReleaseStatus.live,
  String? testAccountId,
}) =>
    YuztooNews(
      id: id,
      title: 'Titre $id',
      body: 'Corps $id',
      publishOn: publishOn,
      releaseStatus: releaseStatus,
      testAccountId: testAccountId,
    );

void main() {
  final now = DateTime(2026, 11, 14, 9);

  group('selectCurrentYuztooNews', () {
    test('returns null when nothing is scheduled', () {
      expect(selectCurrentYuztooNews(const [], now: now), isNull);
    });

    test('returns null when every entry is dated in the future', () {
      final entries = [
        _news('demain', DateTime(2026, 11, 15)),
        _news('apres', DateTime(2026, 11, 16)),
      ];
      expect(selectCurrentYuztooNews(entries, now: now), isNull);
    });

    test('picks the most recent entry already due', () {
      final entries = [
        _news('demain', DateTime(2026, 11, 15)),
        _news('aujourdhui', DateTime(2026, 11, 14)),
        _news('hier', DateTime(2026, 11, 13)),
      ];
      expect(selectCurrentYuztooNews(entries, now: now)?.id, 'aujourdhui');
    });

    test('keeps showing the last entry when no newer one is scheduled', () {
      final entries = [_news('semaine_derniere', DateTime(2026, 11, 7))];
      expect(
        selectCurrentYuztooNews(entries, now: now)?.id,
        'semaine_derniere',
      );
    });

    test('ignores the document order and never leaks a future entry', () {
      final entries = [
        _news('hier', DateTime(2026, 11, 13)),
        _news('la_semaine_prochaine', DateTime(2026, 11, 20)),
        _news('ce_matin', DateTime(2026, 11, 14, 7)),
      ];
      expect(selectCurrentYuztooNews(entries, now: now)?.id, 'ce_matin');
    });

    test('an entry dated later today is not published yet', () {
      final entries = [_news('ce_soir', DateTime(2026, 11, 14, 18))];
      expect(selectCurrentYuztooNews(entries, now: now), isNull);
    });

    test('hides draft entries', () {
      final entries = [
        _news(
          'draft',
          DateTime(2026, 11, 14),
          releaseStatus: YuztooNewsReleaseStatus.draft,
        ),
      ];
      expect(selectCurrentYuztooNews(entries, now: now), isNull);
    });

    test('preview is visible only to the test account', () {
      final entries = [
        _news(
          'preview',
          DateTime(2026, 11, 14),
          releaseStatus: YuztooNewsReleaseStatus.preview,
          testAccountId: 'tester',
        ),
        _news('live_old', DateTime(2026, 11, 13)),
      ];
      expect(
        selectCurrentYuztooNews(entries, now: now, viewerUid: 'tester')?.id,
        'preview',
      );
      expect(
        selectCurrentYuztooNews(entries, now: now, viewerUid: 'other')?.id,
        'live_old',
      );
      expect(
        selectCurrentYuztooNews(entries, now: now)?.id,
        'live_old',
      );
    });
  });
}
