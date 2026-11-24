import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/french_commune.dart';
import '../../infrastructure/city_catalog_repository.dart';
import '../../utils/cities.dart';
import '../../utils/city_match.dart';
import '../../utils/local_area_cities.dart';
import '../constants/merchant_colors.dart';

/// Opens the searchable French city picker and resolves with the chosen
/// commune, or `null` when dismissed.
///
/// Typed queries hit the official commune catalog (geo.api.gouv.fr, ~35 000
/// communes, most populous first); [suggestedCities] (the bundled
/// [frenchCities] by default) is shown before typing and used as the offline
/// fallback.
///
/// Cities whose name matches one of [excludedCities] (case-insensitive) are
/// hidden, e.g. cities the user is already connected to.
Future<FrenchCommune?> showCitySearchSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? selectedCity,
  List<String> suggestedCities = frenchCities,
  Iterable<String> excludedCities = const <String>[],
  Color backgroundColor = MerchantColors.navyCard,
  bool isDismissible = true,
  CityCatalogRepository? cityCatalog,
}) {
  return showModalBottomSheet<FrenchCommune>(
    context: context,
    backgroundColor: backgroundColor,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CitySearchSheet(
      title: title,
      subtitle: subtitle,
      selectedCity: selectedCity,
      suggestedCities: suggestedCities,
      excludedCities: excludedCities,
      cityCatalog: cityCatalog,
    ),
  );
}

class CitySearchSheet extends StatefulWidget {
  const CitySearchSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.selectedCity,
    this.suggestedCities = frenchCities,
    this.excludedCities = const <String>[],
    this.cityCatalog,
  });

  final String title;
  final String? subtitle;
  final String? selectedCity;
  final List<String> suggestedCities;
  final Iterable<String> excludedCities;
  final CityCatalogRepository? cityCatalog;

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  static const int _minApiQueryLength = 2;
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  late final CityCatalogRepository _catalog;
  late final bool _ownsCatalog;
  late final Set<String> _excluded;

  late List<FrenchCommune> _results;
  Timer? _debounceTimer;
  int _searchToken = 0;
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ownsCatalog = widget.cityCatalog == null;
    // Interactive search: the public API regularly needs 5–10 s, so wait
    // longer than background lookups before falling back to the local list.
    _catalog = widget.cityCatalog ??
        CityCatalogRepository(timeout: const Duration(seconds: 12));
    _excluded = widget.excludedCities.map(CityMatch.key).toSet();
    _results = _localMatches('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchToken++;
    _controller.dispose();
    if (_ownsCatalog) _catalog.close();
    super.dispose();
  }

  bool _isAllowed(String name) => !_excluded.contains(CityMatch.key(name));

  /// Offline / slow-API fallback. Accent, case and hyphen insensitive
  /// (« hericourt » → Héricourt, « chatenois les forges » → Châtenois-les-
  /// Forges) over the suggestions + the bundled launch-area communes.
  /// Names starting with the query come first.
  List<FrenchCommune> _localMatches(String query) {
    if (query.trim().isEmpty) {
      return widget.suggestedCities
          .where(_isAllowed)
          .map((name) => FrenchCommune(name: name))
          .toList(growable: false);
    }
    final q = CityMatch.key(query);
    final seen = <String>{};
    final starts = <String>[];
    final contains = <String>[];
    for (final name in [...widget.suggestedCities, ...localAreaCities]) {
      final k = CityMatch.key(name);
      if (!seen.add(k) || !_isAllowed(name)) continue;
      if (k.startsWith(q)) {
        starts.add(name);
      } else if (k.contains(q)) {
        contains.add(name);
      }
    }
    return [...starts, ...contains]
        .take(40)
        .map((name) => FrenchCommune(name: name))
        .toList(growable: false);
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    final query = value.trim();
    final token = ++_searchToken;

    if (query.length < _minApiQueryLength) {
      setState(() {
        _query = query;
        _loading = false;
        _results = _localMatches(query);
      });
      return;
    }

    setState(() {
      _query = query;
      _loading = true;
    });
    _debounceTimer = Timer(_debounce, () async {
      final apiResults = await _catalog.searchCommunes(query, limit: 25);
      if (!mounted || token != _searchToken) return;
      final allowed =
          apiResults.where((c) => _isAllowed(c.name)).toList(growable: false);
      setState(() {
        _loading = false;
        _results = apiResults.isNotEmpty ? allowed : _localMatches(query);
      });
    });
  }

  void _clear() {
    _controller.clear();
    _onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Closed keyboard: comfortable 70 % sheet. Open keyboard: grow to
        // every pixel above it so results are never hidden underneath.
        final sheetHeight = keyboardOpen
            ? constraints.maxHeight - keyboardHeight
            : constraints.maxHeight * 0.7;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: SizedBox(
            height: sheetHeight.clamp(160.0, constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                ),
                Expanded(
                  child: _buildResults(
                    bottomPadding:
                        keyboardOpen ? 8 : media.viewPadding.bottom + 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            cursorColor: MerchantColors.gold,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher une ville...',
              hintStyle: GoogleFonts.outfit(
                color: MerchantColors.textGrey,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: MerchantColors.textGrey,
                size: 20,
              ),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MerchantColors.gold,
                        ),
                      ),
                    )
                  : _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: MerchantColors.textGrey,
                            size: 18,
                          ),
                          onPressed: _clear,
                        )
                      : null,
              filled: true,
              fillColor: MerchantColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MerchantColors.gold),
              ),
            ),
            onChanged: _onQueryChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildResults({required double bottomPadding}) {
    if (_results.isEmpty) {
      return Center(
        child: Text(
          _loading ? 'Recherche…' : 'Aucune ville trouvée',
          style: GoogleFonts.outfit(
            color: MerchantColors.textGrey,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(top: 4, bottom: bottomPadding),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 20,
        endIndent: 20,
        color: MerchantColors.gold.withValues(alpha: 0.08),
      ),
      itemBuilder: (context, index) {
        final commune = _results[index];
        final selected = widget.selectedCity != null &&
            widget.selectedCity!.toLowerCase() == commune.name.toLowerCase();
        final details = commune.inseeCode == null
            ? null
            : [
                commune.size.label,
                if (commune.locationLabel.isNotEmpty) commune.locationLabel,
              ].join(' · ');

        return InkWell(
          onTap: () => Navigator.of(context).pop(commune),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: MerchantColors.gold.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commune.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? MerchantColors.gold
                              : MerchantColors.textWhite,
                        ),
                      ),
                      if (details != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: MerchantColors.textGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: MerchantColors.gold,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
