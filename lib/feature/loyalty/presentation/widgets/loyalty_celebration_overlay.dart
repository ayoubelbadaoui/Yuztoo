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
import '../../domain/failures/passage_cooldown_failure.dart';
import 'loyalty_celebration_dedupe.dart';

/// Wraps a body widget and listens for the client's session transitioning to
/// `completed` at any followed merchant. When it does, slides in a gold "✓
/// Passage validé" overlay and auto-dismisses after ~4 seconds.
///
/// Completed session docs linger in Firestore. To avoid re-showing on every
/// cold start we (1) wait for SharedPreferences, (2) skip first snapshots of
/// already-terminal sessions, and (3) persist a capped set of seen keys.
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
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _autoDismiss;
  ActiveValidationRequest? _activeCelebration;
  String? _directCelebrationMerchantId;

  bool _prefsReady = false;
  final Set<String> _seenKeys = <String>{};
  final Set<String> _cancelledNotified = <String>{};

  /// Updates received before prefs finished loading — replayed in order.
  final List<_PendingSessionUpdate> _pending = <_PendingSessionUpdate>[];

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
    unawaited(_loadPersisted());
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parsed = LoyaltyCelebrationDedupe.parsePersistedKeys(
        jsonList: prefs.getString(LoyaltyCelebrationDedupe.prefsSeenKeys),
        legacySingle:
            prefs.getString(LoyaltyCelebrationDedupe.prefsLegacyLastSeen),
      );
      _seenKeys.addAll(parsed);
    } catch (_) {
      // Best-effort — first-snapshot rule still blocks cold-start re-fires.
    }
    if (!mounted) return;
    _prefsReady = true;
    final queued = List<_PendingSessionUpdate>.from(_pending);
    _pending.clear();
    for (final update in queued) {
      _onSessionUpdate(
        previous: update.previous,
        session: update.session,
      );
    }
  }

  Future<void> _persistSeenKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LoyaltyCelebrationDedupe.prefsSeenKeys,
        LoyaltyCelebrationDedupe.encodePersistedKeys(_seenKeys),
      );
      // Drop legacy single key once migrated.
      await prefs.remove(LoyaltyCelebrationDedupe.prefsLegacyLastSeen);
    } catch (_) {}
  }

  void _markSeenKey(String key) {
    if (_seenKeys.contains(key)) return;
    _seenKeys.add(key);
    unawaited(_persistSeenKeys());
  }

  void _onSessionUpdate({
    required ActiveValidationRequest? previous,
    required ActiveValidationRequest session,
  }) {
    if (session.isCancelled) {
      _handleCancelled(previous: previous, session: session);
      return;
    }
    if (!session.isCompleted) return;
    _handleCompleted(previous: previous, session: session);
  }

  void _handleCompleted({
    required ActiveValidationRequest? previous,
    required ActiveValidationRequest session,
  }) {
    final decision = LoyaltyCelebrationDedupe.decideCompleted(
      prefsReady: _prefsReady,
      previous: previous,
      session: session,
      seenKeys: _seenKeys,
    );
    switch (decision) {
      case CelebrationDecision.defer:
        _pending.add(
          _PendingSessionUpdate(previous: previous, session: session),
        );
        return;
      case CelebrationDecision.skipAlreadySeen:
        return;
      case CelebrationDecision.markSeenOnly:
        _markSeenKey(LoyaltyCelebrationDedupe.sessionKey(session));
        return;
      case CelebrationDecision.celebrate:
        _markSeenKey(LoyaltyCelebrationDedupe.sessionKey(session));
        setState(() => _activeCelebration = session);
        HapticFeedback.heavyImpact();
        _controller.forward(from: 0);
        _autoDismiss?.cancel();
        _autoDismiss = Timer(const Duration(seconds: 4), _dismiss);
    }
  }

  void _handleCancelled({
    required ActiveValidationRequest? previous,
    required ActiveValidationRequest session,
  }) {
    final decision = LoyaltyCelebrationDedupe.decideCancelled(
      prefsReady: _prefsReady,
      previous: previous,
      session: session,
      cancelledNotified: _cancelledNotified,
    );
    final snackKey = LoyaltyCelebrationDedupe.cancelledSnackKey(session);
    switch (decision) {
      case CelebrationDecision.defer:
        _pending.add(
          _PendingSessionUpdate(previous: previous, session: session),
        );
        return;
      case CelebrationDecision.skipAlreadySeen:
        return;
      case CelebrationDecision.markSeenOnly:
        _cancelledNotified.add(snackKey);
        return;
      case CelebrationDecision.celebrate:
        _cancelledNotified.add(snackKey);
        final message = session.cancelReason == 'passage_cooldown'
            ? const PassageCooldownFailure().message
            : 'Demande de passage annulée ou refusée.';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                message,
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
    }
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
              onSessionUpdate: _onSessionUpdate,
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

class _PendingSessionUpdate {
  const _PendingSessionUpdate({
    required this.previous,
    required this.session,
  });

  final ActiveValidationRequest? previous;
  final ActiveValidationRequest session;
}

class _SessionListener extends ConsumerWidget {
  const _SessionListener({
    required this.merchantId,
    required this.onSessionUpdate,
  });

  final String merchantId;
  final void Function({
    required ActiveValidationRequest? previous,
    required ActiveValidationRequest session,
  }) onSessionUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ActiveValidationRequest?>>(
      clientActiveValidationSessionProvider(merchantId),
      (prev, next) {
        next.whenData((session) {
          if (session == null) return;
          onSessionUpdate(
            previous: prev?.asData?.value,
            session: session,
          );
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
