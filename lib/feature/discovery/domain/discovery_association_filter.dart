import '../../merchant/domain/entities/merchant.dart';

String _merchantDiscoveryHaystack(Merchant merchant) {
  return <String>[
    if (merchant.subcategoryTitle != null) merchant.subcategoryTitle!,
    ...?merchant.categories,
    if (merchant.displayCategory != null) merchant.displayCategory!,
  ].map((s) => s.toLowerCase()).join(' ');
}

/// True when a merchant is an **artiste** (individual creator), not a civic
/// association structure.
bool isArtisteMerchant(Merchant merchant) {
  final categoryId = merchant.categoryId?.trim().toLowerCase() ?? '';
  if (categoryId == 'association') return false;

  final haystack = _merchantDiscoveryHaystack(merchant);
  return haystack.contains('artiste') || haystack.contains('artist');
}

/// True when a merchant is an **association / collectivité** (city-scoped tab).
bool isAssociationMerchant(Merchant merchant) {
  final categoryId = merchant.categoryId?.trim().toLowerCase() ?? '';
  if (categoryId == 'association') return true;

  if (isArtisteMerchant(merchant)) return false;

  final haystack = _merchantDiscoveryHaystack(merchant);
  return haystack.contains('association') ||
      haystack.contains('collectivité') ||
      haystack.contains('collectivite') ||
      haystack.contains('ccas') ||
      haystack.contains('mairie');
}

/// Legacy helper — artiste **or** association (avoid for new tabs).
bool isAssociationOrArtisteMerchant(Merchant merchant) =>
    isArtisteMerchant(merchant) || isAssociationMerchant(merchant);

List<Merchant> _filterActiveDeduped(
  List<Merchant> merchants,
  bool Function(Merchant) predicate,
) {
  final seen = <String>{};
  final out = <Merchant>[];
  for (final m in merchants) {
    if (m.status != 'active') continue;
    if (!predicate(m)) continue;
    if (!seen.add(m.id)) continue;
    out.add(m);
  }
  return out;
}

/// All active **associations** in [merchants] (typically the user's city
/// catalogue). Does **not** exclude followed merchants — they stay visible.
List<Merchant> filterAssociationMerchants(List<Merchant> merchants) =>
    _filterActiveDeduped(merchants, isAssociationMerchant);

/// All active **artistes** in [merchants] (national catalogue, any city).
List<Merchant> filterArtisteMerchants(List<Merchant> merchants) =>
    _filterActiveDeduped(merchants, isArtisteMerchant);

/// @deprecated Use [filterAssociationMerchants] or [filterArtisteMerchants].
List<Merchant> filterAssociationArtisteMerchants(List<Merchant> merchants) =>
    _filterActiveDeduped(merchants, isAssociationOrArtisteMerchant);
