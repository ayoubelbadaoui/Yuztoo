import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/infrastructure/city_catalog_repository.dart';
import '../constants/signup_constants.dart';

class CitySelectionModal {
  /// [cityCatalog] is injectable so unit tests can stub the network layer;
  /// production callers pass `null` and the modal builds a default
  /// repository internally.
  static Future<void> show(
    BuildContext context, {
    required List<String> cities,
    required String? selectedCity,
    required ValueChanged<String> onCitySelected,
    required VoidCallback onValidateCity,
    CityCatalogRepository? cityCatalog,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: SignupConstants.bgDark2,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _CitySelectionSheet(
        cities: cities,
        selectedCity: selectedCity,
        onCitySelected: onCitySelected,
        onValidateCity: onValidateCity,
        cityCatalog: cityCatalog,
      ),
    );
  }
}

class _CitySelectionSheet extends StatefulWidget {
  const _CitySelectionSheet({
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
    required this.onValidateCity,
    this.cityCatalog,
  });

  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String> onCitySelected;
  final VoidCallback onValidateCity;
  final CityCatalogRepository? cityCatalog;

  @override
  State<_CitySelectionSheet> createState() => _CitySelectionSheetState();
}

class _CitySelectionSheetState extends State<_CitySelectionSheet> {
  late final TextEditingController _searchController;
  late final CityCatalogRepository _repo;
  late final bool _ownsRepo;

  List<String> _filteredCities = [];
  Timer? _debounceTimer;
  int _searchToken = 0;
  bool _isLoading = false;
  bool _usingApi = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _ownsRepo = widget.cityCatalog == null;
    _repo = widget.cityCatalog ?? CityCatalogRepository();
    _filteredCities = widget.cities;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchToken++;
    _searchController.dispose();
    if (_ownsRepo) {
      _repo.close();
    }
    super.dispose();
  }

  void _runSearch(String value) {
    _debounceTimer?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      _searchToken++;
      if (!mounted) return;
      setState(() {
        _filteredCities = widget.cities;
        _isLoading = false;
        _usingApi = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final myToken = ++_searchToken;
      _repo.search(query, limit: 25).then((apiResults) {
        if (!mounted || myToken != _searchToken) return;
        final lower = query.toLowerCase();
        final fallback = widget.cities
            .where((c) => c.toLowerCase().contains(lower))
            .toList();
        final next = apiResults.isNotEmpty ? apiResults : fallback;
        setState(() {
          _filteredCities = next;
          _isLoading = false;
          _usingApi = apiResults.isNotEmpty;
        });
      }).catchError((_) {
        if (!mounted || myToken != _searchToken) return;
        final lower = query.toLowerCase();
        setState(() {
          _filteredCities = widget.cities
              .where((c) => c.toLowerCase().contains(lower))
              .toList();
          _isLoading = false;
          _usingApi = false;
        });
      });
    });
  }

  void _selectCity(String city) {
    _debounceTimer?.cancel();
    _searchToken++;
    final onSelected = widget.onCitySelected;
    final onValidate = widget.onValidateCity;
    Navigator.of(context).pop();
    // Run parent updates after the sheet is gone (avoids setState during
    // route teardown — common red-screen on Android during onboarding).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSelected(city);
      onValidate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
    // Shrink when the keyboard is open so the list stays bounded.
    final sheetHeight = (maxHeight - viewInsets.bottom).clamp(280.0, maxHeight);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: SignupConstants.borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez votre ville',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SignupConstants.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: SignupConstants.textLight,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une ville...',
                      hintStyle: const TextStyle(
                        color: SignupConstants.textGrey,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: SignupConstants.primaryGold,
                      ),
                      filled: true,
                      fillColor: SignupConstants.bgDark1,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: SignupConstants.borderColor,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: SignupConstants.borderColor,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: SignupConstants.primaryGold,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: _runSearch,
                  ),
                  if (_isLoading || _usingApi) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: SignupConstants.primaryGold,
                            ),
                          ),
                        if (_isLoading) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isLoading
                                ? 'Recherche en cours…'
                                : 'Catalogue en ligne — 35 000+ communes',
                            style: const TextStyle(
                              fontSize: 11,
                              color: SignupConstants.textGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _filteredCities.isEmpty
                  ? Center(
                      child: Text(
                        _isLoading
                            ? 'Recherche…'
                            : 'Aucune ville trouvée',
                        style: const TextStyle(
                          fontSize: 14,
                          color: SignupConstants.textGrey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        final isSelected = widget.selectedCity == city;

                        return GestureDetector(
                          onTap: () => _selectCity(city),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isSelected
                                  ? SignupConstants.primaryGold
                                      .withValues(alpha: 0.15)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? SignupConstants.primaryGold
                                    : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    city,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? SignupConstants.primaryGold
                                          : SignupConstants.textLight,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: SignupConstants.primaryGold,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
