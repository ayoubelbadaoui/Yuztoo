import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/infrastructure/city_catalog_repository.dart';
import '../constants/signup_constants.dart';

class CitySelectionModal {
  /// [cityCatalog] is injectable so unit tests can stub the network layer;
  /// production callers pass `null` and the modal builds a default
  /// repository internally.
  static void show(
    BuildContext context, {
    required List<String> cities,
    required String? selectedCity,
    required Function(String) onCitySelected,
    required Function() onValidateCity,
    CityCatalogRepository? cityCatalog,
  }) {
    final TextEditingController searchController = TextEditingController();
    // The bundled `cities` list is the offline / empty-query fallback. When
    // the user types, we hit `geo.api.gouv.fr` for the much larger live
    // catalog (35 000+ communes, ranked by population). On any error we
    // silently use the bundled list filtered by substring.
    final repo = cityCatalog ?? CityCatalogRepository();
    final ownsRepo = cityCatalog == null;
    List<String> filteredCities = cities;
    Timer? debounceTimer;
    int searchToken = 0;
    bool isLoading = false;
    bool usingApi = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: SignupConstants.bgDark2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // Tear-down hooks attached to the route's pop future. Putting this
        // here (rather than in `runSearch`) guarantees we drop pending
        // network work even when the user dismisses the sheet by tapping
        // outside instead of selecting a city.
        ModalRoute.of(context)?.popped.whenComplete(() {
          debounceTimer?.cancel();
          searchToken++; // invalidate any in-flight result
          searchController.dispose();
          if (ownsRepo) repo.close();
        });
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void runSearch(String value) {
              debounceTimer?.cancel();
              final query = value.trim();
              if (query.isEmpty) {
                searchToken++; // invalidate any in-flight request
                setState(() {
                  filteredCities = cities;
                  isLoading = false;
                  usingApi = false;
                });
                return;
              }
              setState(() => isLoading = true);
              debounceTimer = Timer(const Duration(milliseconds: 300), () {
                final myToken = ++searchToken;
                repo.search(query, limit: 25).then((apiResults) {
                  // Drop the response if a newer query has fired in the
                  // meantime — keeps the list from flashing back to a
                  // stale result set.
                  if (myToken != searchToken) return;
                  // Static fallback: substring filter on the bundled list.
                  final lower = query.toLowerCase();
                  final fallback = cities
                      .where((c) => c.toLowerCase().contains(lower))
                      .toList();
                  // Prefer API when it has anything to show; otherwise
                  // keep the user moving with the static list.
                  final next = apiResults.isNotEmpty ? apiResults : fallback;
                  setState(() {
                    filteredCities = next;
                    isLoading = false;
                    usingApi = apiResults.isNotEmpty;
                  });
                }).catchError((_) {
                  if (myToken != searchToken) return;
                  final lower = query.toLowerCase();
                  setState(() {
                    filteredCities = cities
                        .where((c) => c.toLowerCase().contains(lower))
                        .toList();
                    isLoading = false;
                    usingApi = false;
                  });
                });
              });
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
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
                          // Search field
                          TextField(
                            controller: searchController,
                            style: const TextStyle(color: SignupConstants.textLight, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Rechercher une ville...',
                              hintStyle: const TextStyle(color: SignupConstants.textGrey, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: SignupConstants.primaryGold),
                              filled: true,
                              fillColor: SignupConstants.bgDark1,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: SignupConstants.primaryGold,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: runSearch,
                          ),
                          if (isLoading || usingApi) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: SignupConstants.primaryGold,
                                    ),
                                  ),
                                if (isLoading) const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isLoading
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
                    // Cities list
                    Expanded(
                      child: filteredCities.isEmpty
                          ? Center(
                              child: Text(
                                isLoading
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
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                final city = filteredCities[index];
                                final isSelected = selectedCity == city;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Update city first, then validate after state updates
                                    onCitySelected(city);
                                    // Validate after state has been updated
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      onValidateCity();
                                    });
                                  },
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
                                          ? SignupConstants.primaryGold.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? SignupConstants.primaryGold
                                            : Colors.transparent,
                                        width: isSelected ? 2 : 0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
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
          },
        );
      },
    );
  }
}

