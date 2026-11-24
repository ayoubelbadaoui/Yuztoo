import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/core/infrastructure/city_catalog_repository.dart';
import 'package:flutter_yuztoo/core/shared/widgets/city_search_sheet.dart';

class _FakeCityCatalog extends CityCatalogRepository {
  _FakeCityCatalog(this.results);

  final List<FrenchCommune> results;
  final List<String> queries = <String>[];

  @override
  Future<List<FrenchCommune>> searchCommunes(
    String query, {
    int limit = 20,
  }) async {
    queries.add(query);
    return results;
  }

  @override
  void close() {}
}

const _screen = Size(400, 800);
const _keyboard = 350.0;

Future<FrenchCommune? Function()> _pump(
  WidgetTester tester, {
  required CityCatalogRepository catalog,
  double keyboard = 0,
  List<String> suggested = const ['Belfort', 'Bordeaux', 'Brest'],
  List<String> excluded = const <String>[],
}) async {
  FrenchCommune? picked;
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: _screen,
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                picked = await showCitySearchSheet(
                  context,
                  title: 'Ajouter une ville connectée',
                  suggestedCities: suggested,
                  excludedCities: excluded,
                  cityCatalog: catalog,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  return () => picked;
}

void main() {
  testWidgets('results stay visible above an open keyboard', (tester) async {
    await _pump(tester,
        catalog: _FakeCityCatalog(const []), keyboard: _keyboard);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final firstResult = tester.getRect(find.text('Belfort'));
    expect(firstResult.bottom, lessThan(_screen.height - _keyboard));
    final list = tester.getRect(find.byType(ListView));
    expect(list.bottom, lessThanOrEqualTo(_screen.height - _keyboard));
  });

  testWidgets('typed query searches the official catalog', (tester) async {
    final catalog = _FakeCityCatalog(const [
      FrenchCommune(
        name: 'Belfort',
        inseeCode: '90010',
        postalCodes: ['90000'],
        population: 46000,
        departmentCode: '90',
      ),
    ]);
    final picked = await _pump(tester, catalog: catalog);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Belf');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(catalog.queries, ['Belf']);
    expect(find.text('Ville · 90000 · dépt. 90'), findsOneWidget);

    await tester.tap(find.text('Belfort'));
    await tester.pumpAndSettle();
    expect(picked()?.inseeCode, '90010');
  });

  testWidgets('already connected cities are hidden', (tester) async {
    await _pump(
      tester,
      catalog: _FakeCityCatalog(const []),
      excluded: const ['bordeaux'],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Belfort'), findsOneWidget);
    expect(find.text('Bordeaux'), findsNothing);
  });
}
