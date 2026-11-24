import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/storefront/application/news_photo_engagement_providers.dart';
import 'package:flutter_yuztoo/feature/storefront/domain/entities/news_photo_engagement.dart';
import 'package:flutter_yuztoo/feature/storefront/domain/repositories/news_photo_engagement_repository.dart';

class _RecordingRepo implements NewsPhotoEngagementRepository {
  String? merchantId;
  String? viewerId;
  List<String>? urls;

  @override
  Future<Map<String, NewsPhotoEngagement>> getEngagementForUrls({
    required String merchantId,
    required List<String> imageUrls,
    String? viewerId,
  }) async {
    this.merchantId = merchantId;
    this.viewerId = viewerId;
    urls = imageUrls;
    return const {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const urls = [
    'https://firebasestorage.googleapis.com/v0/b/yuztoo/o/a.jpg?alt=media&token=1',
    'https://firebasestorage.googleapis.com/v0/b/yuztoo/o/b.jpg?alt=media&token=2',
    'https://firebasestorage.googleapis.com/v0/b/yuztoo/o/c.jpg?alt=media&token=3',
  ];

  Future<_RecordingRepo> load(String? viewerId) async {
    final repo = _RecordingRepo();
    final container = ProviderContainer(overrides: [
      newsPhotoEngagementRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final key = newsPhotoEngagementKey(
      merchantId: 'm1',
      imageUrls: urls,
      viewerId: viewerId,
    );
    await container.read(newsPhotoEngagementMapProvider(key).future);
    return repo;
  }

  test('every gallery URL is loaded, not only the first', () async {
    final repo = await load('viewer1');
    expect(repo.merchantId, 'm1');
    expect(repo.viewerId, 'viewer1');
    expect(repo.urls, urls);
  });

  test('signed-out viewer is passed as null', () async {
    final repo = await load(null);
    expect(repo.viewerId, isNull);
    expect(repo.urls, urls);
  });
}
