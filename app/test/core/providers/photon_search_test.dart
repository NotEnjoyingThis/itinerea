// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/place.dart';
import 'package:itinerea/core/net/http_transport.dart';
import 'package:itinerea/core/net/throttle.dart';
import 'package:itinerea/core/providers/photon_search.dart';

import '../../support/fake_transport.dart';
import '../../support/osm_samples.dart';

Matcher _failure(ServiceFailureKind kind) => throwsA(
  isA<ServiceFailure>().having((failure) => failure.kind, 'kind', kind),
);

void main() {
  late FakeTransport transport;

  setUp(() => transport = FakeTransport(osmServices()));

  PhotonPlaceSearch photon({Uri? baseUrl}) => PhotonPlaceSearch(
    transport: transport,
    baseUrl: baseUrl,
    throttle: Throttle(Duration.zero),
  );

  test('reads names, addresses, positions, identifiers and kinds', () async {
    final places = await photon().search('Uffizi', language: 'en');

    expect(places, hasLength(3));
    final museum = places.first;
    expect(museum.place.name, 'Galleria degli Uffizi');
    expect(museum.place.address, 'Via dei Girolami, Firenze, Italia');
    expect(museum.place.osmId, 'W477279033');
    expect(museum.place.coordinates!.lat, 43.7683129);
    expect(museum.place.coordinates!.lon, 11.2558009);
    expect(museum.category, 'tourism:museum');
    expect(places[1].place.address, 'Via della Ninna 5, Firenze, Italia');
    expect(places[2].place.osmId, 'W23298781');
  });

  test(
    'asks the public instance with the text, a limit and the language',
    () async {
      await photon().search('  Uffizi  ', language: 'en');

      final uri = transport.requests.single;
      expect(uri.origin, 'https://photon.komoot.io');
      expect(uri.path, '/api/');
      expect(uri.queryParameters, {'q': 'Uffizi', 'limit': '6', 'lang': 'en'});
    },
  );

  test('a language the public instance refuses asks for local names', () async {
    final search = photon();

    await search.search('Uffizi', language: 'it');
    await search.search('Uffizi', language: 'fr');

    expect(transport.requests.map((uri) => uri.queryParameters['lang']), [
      'default',
      'fr',
    ]);
  });

  test('prefers places near the day, giving only a rounded position', () async {
    await photon().search(
      'Duomo',
      language: 'en',
      near: const Coordinates(lat: 43.771234, lon: 11.256789),
    );

    final query = transport.requests.single.queryParameters;
    expect(query['lat'], '43.77');
    expect(query['lon'], '11.26');
    expect(query['location_bias_scale'], '0.1');
  });

  test('fewer than three letters are not searched', () async {
    expect(await photon().search(' Uf ', language: 'en'), isEmpty);
    expect(transport.requests, isEmpty);
  });

  test('the same text is not asked twice', () async {
    final search = photon();

    await search.search('Uffizi', language: 'en');
    final again = await search.search('  uffizi ', language: 'en');

    expect(again, hasLength(3));
    expect(transport.requests, hasLength(1));
    await search.search('Uffizi', language: 'fr');
    expect(transport.requests, hasLength(2), reason: 'another language');
  });

  test('a failure is not kept: the same text is asked again', () async {
    final search = photon();
    transport.goOffline();

    await expectLater(
      search.search('Uffizi', language: 'en'),
      _failure(ServiceFailureKind.noConnection),
    );
    transport.handler = osmServices();

    expect(await search.search('Uffizi', language: 'en'), hasLength(3));
    expect(transport.requests, hasLength(2));
  });

  test('a service that asks to slow down is busy', () async {
    transport.handler = (_) =>
        jsonAnswer({'message': 'slow down'}, status: 429);

    await expectLater(
      photon().search('Uffizi', language: 'en'),
      _failure(ServiceFailureKind.busy),
    );
  });

  test('an own instance keeps its path', () async {
    transport.handler = (_) => jsonAnswer(photonUffizi);

    await photon(baseUrl: Uri.parse('https://geo.example.org/photon/'))
        .search('Uffizi', language: 'en');

    final uri = transport.requests.single;
    expect('${uri.origin}${uri.path}', 'https://geo.example.org/photon/api/');
  });

  group('reading the answer', () {
    Map<String, Object?> feature(
      Map<String, Object?> properties, [
      List<Object?> coordinates = const [11.33, 43.32],
    ]) => {
      'type': 'Feature',
      'properties': properties,
      'geometry': {'type': 'Point', 'coordinates': coordinates},
    };

    List<PlaceSuggestion> parse(List<Object?> features) =>
        PhotonPlaceSearch.parse({
          'type': 'FeatureCollection',
          'features': features,
        });

    test('an address without a name is named after its street', () {
      final places = parse([
        feature({
          'osm_type': 'N',
          'osm_id': 1,
          'street': 'Via di Città',
          'housenumber': '12',
          'city': 'Siena',
          'country': 'Italia',
        }),
      ]);

      expect(places.single.place.name, 'Via di Città 12');
      expect(places.single.place.address, 'Siena, Italia');
    });

    test('places without a name or a valid position are left out', () {
      final places = parse([
        feature({'osm_type': 'N', 'osm_id': 1}),
        feature({'name': 'Nowhere'}, [11.0, 95.0]),
        feature({'name': 'Nowhere either'}, ['x', 'y']),
        {
          'type': 'Feature',
          'properties': {'name': 'No geometry'},
        },
        'not a feature',
        feature({'name': 'Piazza del Campo'}),
      ]);

      expect(places.map((place) => place.place.name), ['Piazza del Campo']);
      expect(places.single.place.osmId, isNull);
      expect(places.single.category, isNull);
    });

    test('the same place is offered once', () {
      final places = parse([
        feature({'osm_type': 'R', 'osm_id': 42, 'name': 'Siena'}),
        feature({'osm_type': 'R', 'osm_id': 42, 'name': 'Siena'}),
      ]);

      expect(places, hasLength(1));
      expect(places.single.place.osmId, 'R42');
    });

    test('texts from outside are cut to a sensible length', () {
      final places = parse([
        feature({'name': 'a' * 300, 'city': 'b' * 300}),
      ]);

      expect(places.single.place.name, hasLength(200));
      expect(places.single.place.address, hasLength(200));
    });

    test('an answer that is not a list of places is a bad answer', () {
      for (final json in [
        <String, Object?>{},
        <Object?>[],
        'text',
        {'features': 'none'},
      ]) {
        expect(
          () => PhotonPlaceSearch.parse(json),
          _failure(ServiceFailureKind.badResponse),
          reason: '$json',
        );
      }
    });
  });
}
