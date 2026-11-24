import 'package:equatable/equatable.dart';

/// Aggregated client engagement for one Actualité photo.
class NewsPhotoEngagement extends Equatable {
  const NewsPhotoEngagement({
    required this.imageUrl,
    this.likesCount = 0,
    this.viewsCount = 0,
    this.likedByMe = false,
  });

  final String imageUrl;
  final int likesCount;
  final int viewsCount;
  final bool likedByMe;

  static const NewsPhotoEngagement empty = NewsPhotoEngagement(imageUrl: '');

  NewsPhotoEngagement copyWith({
    String? imageUrl,
    int? likesCount,
    int? viewsCount,
    bool? likedByMe,
  }) {
    return NewsPhotoEngagement(
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  @override
  List<Object?> get props => [imageUrl, likesCount, viewsCount, likedByMe];
}
