import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/core/infrastructure/city_catalog_repository.dart';
import 'package:flutter_yuztoo/feature/auth/signup/presentation/widgets/city_selection_modal.dart';

class _FakeCityCatalog extends CityCatalogRepository {
  _FakeCityCatalog(List<String> results, {this.details})
      : results = results
            .map(
              (name) => FrenchCommune(
                name: name,
                inseeCode: name == 'Paris' ? '75056' : null,
                postalCodes:
                    name == 'Paris' ? const <String>['75001'] : const [],
                population: name == 'Paris' ? 2113705 : null,
                departmentCode: name == 'Paris' ? '75' : null,
              ),
            )
            .toList(growable: false);

  final List<FrenchCommune> results;

  /// When set, resolveDetails waits for this (slow geo API).
  final Completer<FrenchCommune>? details;

  @override
  Future<List<FrenchCommune>> searchCommunes(
    String query, {
    int limit = 20,
  }) async {
    return results;
  }

  @override
  Future<FrenchCommune> resolveDetails(FrenchCommune commune) =>
      details?.future ?? Future.value(commune);

  @override
  void close() {}
}

void main() {
  testWidgets('search and select city closes sheet without layout errors',
      (tester) async {
    String? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => CitySelectionModal.show(
                context,
                cities: const ['Paris', 'Lyon', 'Marseille'],
                selectedCity: null,
                onCitySelected: (c) => picked = c,
                onValidateCity: () {},
                cityCatalog: _FakeCityCatalog(const ['Paris']),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Par');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Paris'), findsOneWidget);

    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();

    expect(picked, 'Paris');
  });

  testWidgets('sheet has bounded height while keyboard is open',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => CitySelectionModal.show(
                context,
                cities: const ['Paris', 'Lyon'],
                selectedCity: null,
                onCitySelected: (_) {},
                onValidateCity: () {},
                cityCatalog: _FakeCityCatalog(const []),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('city is selected before the slow details lookup finishes',
      (tester) async {
    String? picked;
    FrenchCommune? commune;
    final details = Completer<FrenchCommune>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => CitySelectionModal.show(
                context,
                cities: const ['Paris'],
                selectedCity: null,
                onCitySelected: (c) => picked = c,
                onCommuneSelected: (c) => commune = c,
                onValidateCity: () {},
                cityCatalog:
                    _FakeCityCatalog(const ['Paris'], details: details),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'Par');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();

    // Details still pending: the city must already be picked.
    expect(picked, 'Paris');
    expect(commune, isNull);

    details.complete(const FrenchCommune(
      name: 'Paris',
      inseeCode: '75056',
      departmentCode: '75',
    ));
    await tester.pump();
    expect(commune?.inseeCode, '75056');
  });
}
