import '../../merchant/domain/entities/merchant.dart';

/// True when a merchant belongs to the Associations / Artistes discovery slice.
///
/// Matches:
/// * onboarding `categoryId == association`
/// * category / subcategory titles containing association / artiste / artist
bool isAssociationOrArtisteMerchant(Merchant merchant) {
  final categoryId = merchant.categoryId?.trim().toLowerCase() ?? '';
  if (categoryId == 'association') return true;

  final haystack = <String>[
    if (merchant.subcategoryTitle != null) merchant.subcategoryTitle!,
    ...?merchant.categories,
    if (merchant.displayCategory != null) merchant.displayCategory!,
  ].map((s) => s.toLowerCase()).join(' ');

  return haystack.contains('association') ||
      haystack.contains('artiste') ||
      haystack.contains('artist') ||
      haystack.contains('collectivité') ||
      haystack.contains('collectivite');
}

/// Filters an already visibility-filtered catalogue for the Associations chip.
List<Merchant> filterAssociationArtisteMerchants(List<Merchant> merchants) {
  final seen = <String>{};
  final out = <Merchant>[];
  for (final m in merchants) {
    if (m.status != 'active') continue;
    if (!isAssociationOrArtisteMerchant(m)) continue;
    if (!seen.add(m.id)) continue;
    out.add(m);
  }
  return out;
}
