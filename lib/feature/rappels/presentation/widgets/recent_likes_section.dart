import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../application/providers.dart' as rappels_providers;
import '../../domain/entities/merchant_like_alert.dart';
import 'rappels_section_header.dart';

part 'recent_likes_section.part.dart';

/// Who-liked list under Alertes on Vos clients › Aperçu.
class RecentLikesSection extends ConsumerStatefulWidget {
  const RecentLikesSection({
    super.key,
    required this.merchantId,
    this.padding = const EdgeInsets.only(bottom: 20),
  });

  final String merchantId;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<RecentLikesSection> createState() => _RecentLikesSectionState();
}

class _RecentLikesSectionState extends ConsumerState<RecentLikesSection> {
  bool _busyAll = false;

  Future<void> _onMarkAllSeen() async {
    if (_busyAll || widget.merchantId.isEmpty) return;
    setState(() => _busyAll = true);

    final useCase = ref.read(rappels_providers.markLikeAlertsSeenProvider);
    final result = await useCase.call(merchantId: widget.merchantId);

    if (!mounted) return;
    setState(() => _busyAll = false);

    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              f.message,
              style: merchantSnackBarTextOnWarmAccent(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      },
      (_) {
        ref.invalidate(
          rappels_providers.unseenLikeAlertsProvider(widget.merchantId),
        );
        ref.invalidate(
          rappels_providers.rappelsAlertsProvider(widget.merchantId),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Likes marqués comme vus',
              style: merchantSnackBarTextOnGold(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.merchantId.isEmpty) return const SizedBox.shrink();

    final likesAsync = ref.watch(
      rappels_providers.unseenLikeAlertsProvider(widget.merchantId),
    );

    return _buildBody(context, likesAsync);
  }
}
