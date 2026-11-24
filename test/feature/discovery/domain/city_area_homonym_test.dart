import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/core/infrastructure/city_catalog_repository.dart';
import 'package:flutter_yuztoo/feature/discovery/domain/city_agglomeration_expander.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

CityCatalogRepository _catalog() => CityCatalogRepository(
      httpClient: MockClient((req) async {
        final p = req.url.queryParameters;
        if (p['nom'] == 'Saint-Louis') {
          // API order: most populous first → La Réunion.
          return http.Response(
              '[{"nom":"Saint-Louis","code":"97414","codeDepartement":"974","codeEpci":"249740085","population":53000},'
              '{"nom":"Saint-Louis","code":"68297","codeDepartement":"68","codeEpci":"200058485","population":22000}]',
              200,
              headers: _json);
        }
        if (p['codeEpci'] == '247000623' && p['offset'] == '0') {
          return http.Response('[{"nom":"Héricourt"},{"nom":"Brevilliers"}]',
              200,
              headers: _json);
        }
        return http.Response('[]', 200, headers: _json);
      }),
    );

FrenchCommune _c(String name, String dept) =>
    FrenchCommune(name: name, departmentCode: dept);

void main() {
  test('client who picked Héricourt (70): a Héricourt (62) shop is hidden, '
      'Héricourt (70) and shops without data are shown', () async {
    final area = await CityAgglomerationExpander(catalog: _catalog())
        .expandArea(['Héricourt'], knownMetadata: {
      'Héricourt': const FrenchCommune(
        name: 'Héricourt',
        departmentCode: '70',
        epciCode: '247000623',
      ),
    });
    expect(area.names, containsAll(['Héricourt', 'Brevilliers']));
    expect(area.allowsShop(city: 'Héricourt', commune: _c('Héricourt', '70')),
        isTrue);
    expect(area.allowsShop(city: 'Héricourt', commune: _c('Héricourt', '62')),
        isFalse);
    expect(area.allowsShop(city: 'Héricourt'), isTrue,
        reason: 'no stored commune → never hidden');
    expect(area.allowsShop(city: 'Brevilliers', commune: _c('Brevilliers', '70')),
        isTrue,
        reason: 'EPCI peers carry no département → never hidden');
  });

  test('legacy client without stored metadata: an API guess never hides '
      'their own town (Saint-Louis 68 vs 974)', () async {
    final area = await CityAgglomerationExpander(catalog: _catalog())
        .expandArea(['Saint-Louis']);
    expect(
        area.allowsShop(city: 'Saint-Louis', commune: _c('Saint-Louis', '68')),
        isTrue);
  });

  test('stale shop metadata (commune ≠ shop city) is ignored', () async {
    final area = await CityAgglomerationExpander(catalog: _catalog())
        .expandArea(['Héricourt'], knownMetadata: {
      'Héricourt': const FrenchCommune(
          name: 'Héricourt', departmentCode: '70', epciCode: '247000623'),
    });
    expect(area.allowsShop(city: 'Héricourt', commune: _c('Arras', '62')),
        isTrue);
  });
}
