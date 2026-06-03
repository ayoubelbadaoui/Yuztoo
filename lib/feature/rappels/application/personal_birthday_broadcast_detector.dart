/// Pure detector that flags a quick-send composition as a likely
/// **personalised** birthday wish being sent to **everyone** instead of
/// being routed through the auto-trigger system.
///
/// Why this exists: the daily auto-notification cron only fires the
/// "Date anniversaire client" trigger for clients whose DOB is today.
/// A merchant who types "Joyeux anniversaire 🎂" into the quick-send
/// composer and broadcasts to "Tous mes clients" would push that
/// personal wish to every single follower, regardless of their DOB —
/// the exact behaviour the user pushed back against.
///
/// We don't block the send. Some businesses legitimately broadcast
/// "C'est l'anniversaire de notre commerce !" to everyone. We only
/// surface a confirmation when the heuristic matches; the merchant
/// confirms in one tap if they really meant it.
///
/// Heuristic: text contains a personalised birthday cue **and**
/// audience is the broadcast group. Conservative on purpose — false
/// positives cost an extra tap, false negatives spam an entire
/// follower base with the wrong message.
library;

const Set<String> _personalBirthdayCues = <String>{
  'joyeux anniversaire',
  'bon anniversaire',
  'bonne anniversaire',
  'happy birthday',
};

/// Returns true when [text] reads like a personal birthday wish AND
/// [isBroadcastAudience] is true (i.e. "Tous mes clients", no segment
/// filter).
///
/// Case-insensitive. Whitespace-tolerant. Matches anywhere in the
/// message — the merchant typically prefixes a name or wraps the wish
/// with extra context, so substring matching is the right semantics.
bool isLikelyPersonalBirthdayBroadcast({
  required String text,
  required bool isBroadcastAudience,
}) {
  if (!isBroadcastAudience) return false;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  final normalized = trimmed.toLowerCase();
  for (final cue in _personalBirthdayCues) {
    if (normalized.contains(cue)) return true;
  }
  return false;
}
