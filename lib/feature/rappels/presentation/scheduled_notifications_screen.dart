import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../domain/entities/scheduled_notification.dart';
import '../infrastructure/scheduled_notification_repository_provider.dart';

/// Top-level access point for the merchant's pending scheduled
/// notifications. The same list lives inside QuickSendSection on the
/// rappels screen, but a merchant who closed compose and walked away
/// shouldn't have to scroll back through the rappels view to find /
/// cancel an upcoming send. Reachable from Paramètres Pro →
/// "Notifications programmées".
///
/// Read-only beyond the cancel CTA — composing a NEW scheduled notif
/// still happens from the rappels screen so the merchant has the full
/// audience picker, template loader, and quota indicator at hand.
class ScheduledNotificationsScreen extends ConsumerStatefulWidget {
  const ScheduledNotificationsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<ScheduledNotificationsScreen> createState() =>
      _ScheduledNotificationsScreenState();
}

class _ScheduledNotificationsScreenState
    extends ConsumerState<ScheduledNotificationsScreen> {
  Future<void> _cancel(String merchantId, ScheduledNotification s) async {
    final repo = ref.read(scheduledNotificationRepositoryProvider);
    final result = await repo.cancel(
      merchantId: merchantId,
      scheduledId: s.id,
    );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure.message,
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Programmation annulée',
            style: merchantSnackBarTextOnDark(fontWeight: FontWeight.w600),
          ),
          backgroundColor: MerchantColors.bgHeader,
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantId = ref
            .watch(merchant_providers.currentMerchantForOwnerProvider)
            .valueOrNull
            ?.id ??
        '';
    final repo = ref.watch(scheduledNotificationRepositoryProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: merchantId.isEmpty
                    ? _emptyMerchant()
                    : StreamBuilder<List<ScheduledNotification>>(
                        stream: repo.watchAll(merchantId),
                        builder: (context, snap) {
                          if (snap.connectionState ==
                                  ConnectionState.waiting &&
                              !snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: MerchantColors.gold,
                                strokeWidth: 2,
                              ),
                            );
                          }
                          // Pending entries only — sent / cancelled /
                          // failed live in the repo for audit but the
                          // merchant-facing screen is about WHAT'S
                          // STILL COMING.
                          final pending = (snap.data ?? const [])
                              .where((s) => s.isPending)
                              .toList();
                          if (pending.isEmpty) return _emptyState();
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: pending.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _scheduledRow(merchantId, pending[i]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Notifications programmées',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyMerchant() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Aucun commerce associé. Connectez-vous comme commerçant pour '
          'gérer vos notifications programmées.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.gold.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: MerchantColors.gold.withValues(alpha: 0.5),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification programmée',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Programmez un envoi depuis l\'écran « Rappels » '
              '(option « Programmer plus tard »).',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduledRow(String merchantId, ScheduledNotification s) {
    final dt = s.scheduledAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final formatted =
        '${two(dt.day)}/${two(dt.month)}/${dt.year} à ${two(dt.hour)}:${two(dt.minute)}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              color: MerchantColors.gold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatted,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.text,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _audienceSummary(s),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: MerchantColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _confirmAndCancel(merchantId, s),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _audienceSummary(ScheduledNotification s) {
    if (s.audience == 'Tous mes clients') return 'Tous les clients';
    if (s.segments.isEmpty) return 'Audience ciblée';
    final pretty = s.segments
        .map((seg) => seg[0].toUpperCase() + seg.substring(1))
        .join(', ');
    return 'Segment : $pretty';
  }

  Future<void> _confirmAndCancel(
      String merchantId, ScheduledNotification s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.bgHeader,
        title: Text(
          'Annuler cette programmation ?',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'La notification ne sera pas envoyée.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textLightGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Conserver',
                style: GoogleFonts.outfit(color: MerchantColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Annuler l\'envoi',
                style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _cancel(merchantId, s);
  }
}
