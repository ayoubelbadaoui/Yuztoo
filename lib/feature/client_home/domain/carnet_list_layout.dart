import '../../merchant/domain/entities/merchant.dart';

/// Production carnet layout:
/// 1. Followed merchants (reorderable)
/// 2. Optional Yuztoo brand tile (UI-only, not in this list)
/// 3. Own « Mon commerce » tile **last** when present
///
/// Returns the ordered merchant list the carnet should render (excluding the
/// brand tile). Pure function for unit tests.
({
  List<Merchant> followed,
  Merchant? ownMerchant,
}) splitCarnetMerchantsForLayout({
  required List<Merchant> merchants,
  String? ownMerchantId,
}) {
  final ownId = ownMerchantId?.trim();
  Merchant? own;
  final followed = <Merchant>[];
  for (final m in merchants) {
    if (ownId != null && ownId.isNotEmpty && m.id == ownId) {
      own ??= m;
      continue;
    }
    followed.add(m);
  }
  return (followed: followed, ownMerchant: own);
}

/// Rebuilds full ordered ids after a drag on the followed subset.
/// Own merchant stays pinned at the **end** (never reorderable).
List<String> applyCarnetReorder({
  required List<String> orderedIds,
  required String? ownMerchantId,
  required int oldIndex,
  required int newIndex,
}) {
  var ni = newIndex;
  if (ni > oldIndex) ni--;

  final workingList =
      orderedIds.where((id) => id != ownMerchantId).toList();
  if (oldIndex < 0 || oldIndex >= workingList.length) {
    return List<String>.from(orderedIds);
  }
  if (ni < 0) ni = 0;
  if (ni > workingList.length) ni = workingList.length;

  final item = workingList.removeAt(oldIndex);
  workingList.insert(ni, item);

  final showPinned =
      ownMerchantId != null && orderedIds.contains(ownMerchantId);
  if (showPinned) {
    return [...workingList, ownMerchantId];
  }
  return workingList;
}
