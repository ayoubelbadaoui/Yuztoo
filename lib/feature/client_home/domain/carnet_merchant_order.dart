import '../../merchant/domain/entities/merchant.dart';

/// Sort followed merchants for the carnet: saved [sortIndexes] first, then heart level.
int compareCarnetMerchants(
  Merchant a,
  Merchant b, {
  required Map<String, int> sortIndexes,
  required Map<String, int> heartLevels,
}) {
  final ai = sortIndexes[a.id];
  final bi = sortIndexes[b.id];
  if (ai != null && bi != null) return ai.compareTo(bi);
  if (ai != null) return -1;
  if (bi != null) return 1;
  final ah = heartLevels[a.id] ?? 1;
  final bh = heartLevels[b.id] ?? 1;
  return bh.compareTo(ah);
}

bool carnetMerchantIdsEqualOrder(List<Merchant> a, List<Merchant> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id) return false;
  }
  return true;
}
