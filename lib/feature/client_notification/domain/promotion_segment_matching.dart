/// Pure helpers for matching loyalty CRM segments to promotion targeting keys.
///
/// The promo UI exposes: `'vip'`, `'soutien'`, `'habitue'`.
/// The loyalty engine produces: `'vip'`, `'habitue'`, `'nouveau'`, `'inactif'`.
/// `'soutien'` maps to both `'vip'` and `'habitue'` (active regulars).
bool promotionSegmentMatchesTarget(
  String clientSegment,
  List<String> targetSegments,
) {
  for (final target in targetSegments) {
    if (target == clientSegment) return true;
    if (target == 'soutien' &&
        (clientSegment == 'vip' || clientSegment == 'habitue')) {
      return true;
    }
  }
  return false;
}
