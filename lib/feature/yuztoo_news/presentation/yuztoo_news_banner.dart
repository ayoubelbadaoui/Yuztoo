import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../application/providers.dart';
import '../domain/entities/yuztoo_news.dart';
import 'yuztoo_news_detail_page.dart';

/// Permanent "Actu YuzToo" card, pinned at the top of the Alertes tab.
///
/// Renders nothing at all when no entry is due, so the inbox looks exactly
/// like before whenever the team has not scheduled anything.
class YuztooNewsBanner extends ConsumerWidget {
  const YuztooNewsBanner({super.key, this.onMerchantTap});

  /// Used when the actu points at a shop (`cta_merchant_id`).
  final void Function(String merchantId)? onMerchantTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(currentYuztooNewsProvider);
    if (news == null) return const SizedBox.shrink();

    final seenId = ref.watch(yuztooNewsSeenIdProvider).valueOrNull;
    final isUnread = seenId != news.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Material(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(markYuztooNewsSeenProvider).call(news.id);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => YuztooNewsDetailPage(
                  news: news,
                  onMerchantTap: onMerchantTap,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(news: news),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ACTU YUZTOO',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: MerchantColors.gold,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: MerchantColors.gold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        news.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: MerchantColors.textWhite,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        news.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: MerchantColors.textLightGrey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: MerchantColors.gold,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.news});

  final YuztooNews news;

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    if (!news.hasImage) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MerchantColors.gold.withValues(alpha: 0.12),
        ),
        child: const Icon(
          Icons.campaign_rounded,
          color: MerchantColors.gold,
          size: 22,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        news.imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: MerchantColors.gold.withValues(alpha: 0.12),
          child: const Icon(
            Icons.campaign_rounded,
            color: MerchantColors.gold,
            size: 22,
          ),
        ),
      ),
    );
  }
}
