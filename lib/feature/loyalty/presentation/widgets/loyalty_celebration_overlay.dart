import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../auth/core/application/state/auth_state.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../application/active_validation_providers.dart';
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

  void _dismiss() {
    _autoDismiss?.cancel();
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) setState(() => _activeCelebration = null);
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
    return Stack(
      children: [
        widget.child,
        if (isAuthed)
          for (final merchantId in widget.followedMerchantIds)
            _SessionListener(
              merchantId: merchantId,
              onSession: _onSession,
            ),
        if (_activeCelebration != null)
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
                    _bodyLine,
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
