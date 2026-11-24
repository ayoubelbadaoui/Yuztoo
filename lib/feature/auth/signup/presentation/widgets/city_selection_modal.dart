import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/domain/entities/french_commune.dart';
import '../../../../../core/infrastructure/city_catalog_repository.dart';
import '../../../../../core/shared/widgets/city_search_sheet.dart';
import '../../../../../core/utils/city_match.dart';
import '../constants/signup_constants.dart';

class CitySelectionModal {
  /// [cityCatalog] is injectable so unit tests can stub the network layer;
  /// production callers pass `null` and a default repository is built.
  static Future<void> show(
    BuildContext context, {
    required List<String> cities,
    required String? selectedCity,
    required ValueChanged<String> onCitySelected,
    required VoidCallback onValidateCity,
    ValueChanged<FrenchCommune>? onCommuneSelected,
    CityCatalogRepository? cityCatalog,
  }) async {
    final catalog = cityCatalog ??
        CityCatalogRepository(timeout: const Duration(seconds: 12));
    try {
      final commune = await showCitySearchSheet(
        context,
        title: 'Sélectionnez votre ville',
        selectedCity: selectedCity,
        suggestedCities: cities,
        backgroundColor: SignupConstants.bgDark2,
        cityCatalog: catalog,
      );
      if (commune == null) return;

      // Show the chosen city (and enable « Suivant ») as soon as the sheet
      // closes. Waiting for resolveDetails first left the field empty and the
      // button grey for up to 2 s on a slow network — read as « Suivant ne
      // marche pas ».
      onCitySelected(commune.name);
      onValidateCity();

      final detailed = await catalog.resolveDetails(commune).timeout(
            const Duration(seconds: 2),
            onTimeout: () => commune,
          );
      if (detailed.inseeCode != null &&
          CityMatch.key(detailed.name) == CityMatch.key(commune.name)) {
        onCommuneSelected?.call(detailed);
      }
    } finally {
      if (cityCatalog == null) catalog.close();
    }
  }
}
