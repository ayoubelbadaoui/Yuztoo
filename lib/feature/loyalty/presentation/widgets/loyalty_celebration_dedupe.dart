import 'dart:convert';

import '../../domain/entities/active_validation_request.dart';

/// Pure helpers for one-shot « Passage validé » celebration dedupe.
///
/// Completed `active_validations` docs linger in Firestore, so every cold
/// start re-emits them. These helpers decide whether to show UI vs mark seen
/// silently.
class LoyaltyCelebrationDedupe {
  LoyaltyCelebrationDedupe._();

  /// Caps persisted keys so prefs stay bounded across many merchants.
  static const int maxPersistedKeys = 50;

  static const String prefsSeenKeys = 'loyalty_celebration_seen_keys';

  /// Legacy single-string key — migrated into [prefsSeenKeys] on load.
  static const String prefsLegacyLastSeen = 'loyalty_celebration_last_seen_id';

  /// Stable identity for a completed/cancelled terminal session.
  static String sessionKey(ActiveValidationRequest s) {
    final ts = s.completedAt?.millisecondsSinceEpoch;
    if (ts != null && ts > 0) {
      return '${s.merchantId}__${s.clientUid}__$ts';
    }
    // Avoid a forever-rematching `__0` when completedAt is still null.
    final suffix = s.isCancelled ? 'cancelled' : 'completed';
    return '${s.merchantId}__${s.clientUid}__$suffix';
  }

  static String cancelledSnackKey(ActiveValidationRequest s) =>
      '${s.merchantId}__${s.clientUid}__cancelled';

  /// Load seen keys from prefs JSON list, merging the legacy single string.
  static Set<String> parsePersistedKeys({
    String? jsonList,
    String? legacySingle,
  }) {
    final out = <String>{};
    if (jsonList != null && jsonList.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonList);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is String && item.isNotEmpty) out.add(item);
          }
        }
      } catch (_) {
        // Corrupt prefs — start fresh; legacy key may still help.
      }
    }
    if (legacySingle != null && legacySingle.isNotEmpty) {
      out.add(legacySingle);
    }
    return out;
  }

  static String encodePersistedKeys(Set<String> keys) {
    final list = keys.toList(growable: false);
    final start =
        list.length > maxPersistedKeys ? list.length - maxPersistedKeys : 0;
    return jsonEncode(list.sublist(start));
  }

  /// Whether this emission is a live transition to [session] (not a cold
  /// first snapshot of an already-terminal doc).
  static bool isLiveTerminalTransition({
    required ActiveValidationRequest? previous,
    required ActiveValidationRequest session,
  }) {
    if (!session.isCompleted && !session.isCancelled) return false;
    if (previous == null) return false;
    if (previous.isCompleted || previous.isCancelled) return false;
    return true;
  }

  /// Decision for a completed-session emission.
  static CelebrationDecision decideCompleted({
    required bool prefsReady,
    required ActiveValidationRequest? previous,
    required ActiveValidationRequest session,
    required Set<String> seenKeys,
  }) {
    assert(session.isCompleted);
    final key = sessionKey(session);

    if (!prefsReady) {
      return CelebrationDecision.defer;
    }
    if (seenKeys.contains(key)) {
      return CelebrationDecision.skipAlreadySeen;
    }
    if (!isLiveTerminalTransition(previous: previous, session: session)) {
      // Cold-start / first snapshot of an already-completed doc.
      return CelebrationDecision.markSeenOnly;
    }
    return CelebrationDecision.celebrate;
  }

  /// Decision for a cancelled-session emission (snackbar path).
  static CelebrationDecision decideCancelled({
    required bool prefsReady,
    required ActiveValidationRequest? previous,
    required ActiveValidationRequest session,
    required Set<String> cancelledNotified,
  }) {
    assert(session.isCancelled);
    final key = cancelledSnackKey(session);

    if (!prefsReady) {
      return CelebrationDecision.defer;
    }
    if (cancelledNotified.contains(key)) {
      return CelebrationDecision.skipAlreadySeen;
    }
    if (!isLiveTerminalTransition(previous: previous, session: session)) {
      return CelebrationDecision.markSeenOnly;
    }
    return CelebrationDecision.celebrate;
  }
}

enum CelebrationDecision {
  /// Prefs still loading — caller must queue and retry.
  defer,

  /// Already handled — no UI, no write.
  skipAlreadySeen,

  /// First snapshot of an already-terminal session — persist key, no UI.
  markSeenOnly,

  /// Live transition — show celebration / snackbar and persist.
  celebrate,
}
