import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../application/active_validation_providers.dart';
import '../../domain/entities/active_validation_request.dart';

/// Subtle banner shown on the client's loyalty card while their request is
/// in-flight at the given merchant. Copy follows the session state:
///   - awaiting (just sent)        → "Demande envoyée au commerçant…"
///   - awaiting (opened by merchant) → "Le commerçant valide votre passage…"
///
/// Returns SizedBox.shrink() when no session is active or it's already
/// completed/cancelled (the celebration overlay handles those transitions).
class ClientValidationBanner extends ConsumerWidget {
  const ClientValidationBanner({super.key, required this.merchantId});

  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync =
        ref.watch(clientActiveValidationSessionProvider(merchantId));
    return sessionAsync.when(
      data: (session) {
        if (session == null) return const SizedBox.shrink();
        if (session.status != ActiveValidationStatus.awaiting) {
          return const SizedBox.shrink();
        }
        if (session.isExpired) return const SizedBox.shrink();
        final opened = session.openedAt != null;
        final copy = opened
            ? 'Le commerçant valide votre passage…'
            : 'Demande envoyée au commerçant…';
        return _BannerBody(copy: copy);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({required this.copy});

  final String copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MerchantColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: MerchantColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              copy,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MerchantColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
