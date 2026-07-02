import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../application/active_validation_providers.dart';
import '../../application/client_loyalty_providers.dart';
import '../../domain/entities/active_validation_request.dart';

/// Wraps a body widget and listens for the client's session transitioning to
/// `completed` at any followed merchant. When it does, slides in a gold "✓
/// Passage validé" overlay and auto-dismisses after ~4 seconds.
///
/// To avoid re-triggering on cold-start when a session completed while the
/// app was closed, the last-seen completed session id is persisted in
/// SharedPreferences.
class LoyaltyCelebrationOverlay extends ConsumerStatefulWidget {
  const LoyaltyCelebrationOverlay({
    super.key,
    required this.followedMerchantIds,
    required this.child,
  });

  /// Merchants this client follows — the celebration overlay listens to all
  /// of their session streams to spot a completed transition.
  final List<String> followedMerchantIds;
  final Widget child;

  @override
  ConsumerState<LoyaltyCelebrationOverlay> createState() =>
      _LoyaltyCelebrationOverlayState();
}

class _LoyaltyCelebrationOverlayState
    extends ConsumerState<LoyaltyCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  static const String _prefsKey = 'loyalty_celebration_last_seen_id';
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _autoDismiss;
  ActiveValidationRequest? _activeCelebration;
  String? _directCelebrationMerchantId;
  final Set<String> _seenInSession = <String>{};
  String? _persistedLastSeen;

  final Set<String> _cancelledNotified = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _persistedLastSeen = prefs.getString(_prefsKey);
    } catch (_) {
      // Best-effort — if shared_preferences fails we just risk re-firing.
    }
  }

  Future<void> _markSeen(ActiveValidationRequest session) async {
    final key = _sessionKey(session);
    _seenInSession.add(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, key);
      _persistedLastSeen = key;
    } catch (_) {}
  }

  String _sessionKey(ActiveValidationRequest s) {
    final ts = s.completedAt?.millisecondsSinceEpoch ?? 0;
    return '${s.merchantId}__${s.clientUid}__$ts';
  }

  void _onSession(ActiveValidationRequest session) {
    if (session.isCancelled) {
      final k = '${session.merchantId}__${session.clientUid}__cancelled';
      if (_cancelledNotified.contains(k)) return;
      _cancelledNotified.add(k);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              'Demande de passage annulée ou refusée.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
      return;
    }
    if (!session.isCompleted) return;
    final key = _sessionKey(session);
    if (_seenInSession.contains(key)) return;
    if (_persistedLastSeen == key) {
      _seenInSession.add(key);
      return;
    }
    setState(() => _activeCelebration = session);
    HapticFeedback.heavyImpact();
    _controller.forward(from: 0);
    _autoDismiss?.cancel();
    _autoDismiss = Timer(const Duration(seconds: 4), _dismiss);
    _markSeen(session);
  }

  /// Direct visit (NFC tag tap, deep link, in-app QR) — the use case
  /// records the passage without an `active_validations` doc, so we
  /// celebrate from a one-shot provider signal instead of a Firestore
  /// session transition. Idempotent: the same merchantId from the same
  /// scan only fires once.
  void _onDirectVisit(String merchantId) {
    if (merchantId.isEmpty) return;
    if (_directCelebrationMerchantId == merchantId) return;
    setState(() {
      _directCelebrationMerchantId = merchantId;
      _activeCelebration = null;
    });
    HapticFeedback.heavyImpact();
    _controller.forward(from: 0);
    _autoDismiss?.cancel();
    _autoDismiss = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _autoDismiss?.cancel();
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeCelebration = null;
          _directCelebrationMerchantId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(auth_providers.authStateProvider);
    final isAuthed = auth is Authenticated;

    // One-shot direct-visit celebration. The store_profile flow sets the
    // merchantId after [ProcessVitrineScanVisit] returns
    // [ScanVisitVisitRecorded]; we consume + clear it inside a post-frame
    // callback so the same scan doesn't re-fire on rebuild.
    ref.listen<String?>(pendingDirectVisitCelebrationProvider,
        (previous, next) {
      if (next == null || next.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onDirectVisit(next);
        ref.read(pendingDirectVisitCelebrationProvider.notifier).state = null;
      });
    });

    final showSessionCard = _activeCelebration != null;
    final showDirectCard =
        !showSessionCard && _directCelebrationMerchantId != null;

    return Stack(
      children: [
        widget.child,
        if (isAuthed)
          for (final merchantId in widget.followedMerchantIds)
            _SessionListener(
              merchantId: merchantId,
              onSession: _onSession,
            ),
        if (showSessionCard)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: SafeArea(
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _opacity,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: _CelebrationCard(session: _activeCelebration!),
                  ),
                ),
              ),
            ),
          ),
        if (showDirectCard)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: SafeArea(
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _opacity,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: const _DirectVisitCelebrationCard(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SessionListener extends ConsumerWidget {
  const _SessionListener({required this.merchantId, required this.onSession});

  final String merchantId;
  final ValueChanged<ActiveValidationRequest> onSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ActiveValidationRequest?>>(
      clientActiveValidationSessionProvider(merchantId),
      (prev, next) {
        next.whenData((session) {
          if (session != null) onSession(session);
        });
      },
    );
    return const SizedBox.shrink();
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({required this.session});

  final ActiveValidationRequest session;

  String get _bodyLine {
    final delta = session.resultValidatedDelta ?? 0;
    final spendDelta = session.resultSpendDelta ?? 0.0;
    final config = session.programSnapshot;
    if (config.triggerType == LoyaltyTriggerType.purchaseTotal &&
        spendDelta > 0) {
      return 'Achat de ${spendDelta.toStringAsFixed(2)} € comptabilisé.';
    }
    if (delta > 0) {
      return '+1 passage validé.';
    }
    return 'Passage enregistré.';
  }

  @override
  Widget build(BuildContext context) =>
      _CelebrationCardChrome(bodyLine: _bodyLine);
}

/// Card variant for direct visits (scan / NFC tap / deep link). The
/// merchant validation mode for these is by definition `automatic`, so
/// the body line is fixed.
class _DirectVisitCelebrationCard extends StatelessWidget {
  const _DirectVisitCelebrationCard();

  @override
  Widget build(BuildContext context) =>
      const _CelebrationCardChrome(bodyLine: '+1 passage validé.');
}

class _CelebrationCardChrome extends StatelessWidget {
  const _CelebrationCardChrome({required this.bodyLine});

  final String bodyLine;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [MerchantColors.gold, Color(0xFFD4AF37)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: MerchantColors.darkOverlay.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: MerchantColors.darkOverlay,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passage validé ✓',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.darkOverlay,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bodyLine,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.darkOverlay.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
