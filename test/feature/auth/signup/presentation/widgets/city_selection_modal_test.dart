import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/city_catalog_repository.dart';
import 'package:flutter_yuztoo/feature/auth/signup/presentation/widgets/city_selection_modal.dart';

class _FakeCityCatalog extends CityCatalogRepository {
  _FakeCityCatalog(this.results);

  final List<String> results;

  @override
  Future<List<String>> search(String query, {int limit = 20}) async {
    return results;
  }

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

  testWidgets('sheet has bounded height while keyboard is open', (tester) async {
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
}
