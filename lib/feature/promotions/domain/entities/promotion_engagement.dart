import 'package:equatable/equatable.dart';

/// Like counters + "liked by me" for one promotion.
class PromotionEngagement extends Equatable {
  const PromotionEngagement({
    required this.promotionId,
    this.likesCount = 0,
    this.likedByMe = false,
  });

  final String promotionId;
  final int likesCount;
  final bool likedByMe;

  PromotionEngagement copyWith({
    int? likesCount,
    bool? likedByMe,
  }) =>
      PromotionEngagement(
        promotionId: promotionId,
        likesCount: likesCount ?? this.likesCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );

  @override
  List<Object?> get props => [promotionId, likesCount, likedByMe];
}
