// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/place.dart';
import 'package:itinerea/core/net/http_transport.dart';
import 'package:itinerea/core/net/throttle.dart';
import 'package:itinerea/core/providers/nominatim_details.dart';

import '../../support/fake_transport.dart';
import '../../support/osm_samples.dart';

Matcher _failure(ServiceFailureKind kind) => throwsA(
  isA<ServiceFailure>().having((failure) => failure.kind, 'kind', kind),
);

void main() {
  late FakeTransport transport;
  final now = DateTime.utc(2026, 11, 16, 10);

  setUp(() => transport = FakeTransport(osmServices()));

  NominatimPlaceDetails nominatim() => NominatimPlaceDetails(
    transport: transport,
    throttle: Throttle(Duration.zero),
    now: () => now,
  );

  PlaceDetails parse(Map<String, Object?> tags) => NominatimPlaceDetails.parse([
    {'osm_type': 'node', 'osm_id': 1, 'extratags': tags},
  ], fetchedAt: now);

  test('reads opening hours, phone, website and Wikidata', () async {
    final details = await nominatim().details('W477279033', language: 'it');

    expect(
      details.openingHours,
      'Tu-Su 08:15-18:30; Mo off; Jan 1 off; Dec 25 off',
    );
    expect(details.phone, '+39 055 294883');
    expect(details.website, 'https://www.uffizi.it');
    expect(details.wikidataId, 'Q51252');
    expect(details.fetchedAt, now);
  });

  test('asks one lookup with the extra tags, never a search', () async {
    await nominatim().details('W477279033', language: 'it');

    final uri = transport.requests.single;
    expect(uri.origin, 'https://nominatim.openstreetmap.org');
    expect(uri.path, '/lookup');
    expect(uri.queryParameters, {
      'osm_ids': 'W477279033',
      'format': 'jsonv2',
      'extratags': '1',
      'addressdetails': '0',
      'accept-language': 'it',
    });
  });

  test(
    'a place without those tags gives empty details, not an error',
    () async {
      transport.handler = osmServices(lookup: nominatimNothing);

      final details = await nominatim().details('W23298781', language: 'en');

      expect(details.openingHours, isNull);
      expect(details.phone, isNull);
      expect(details.website, isNull);
      expect(details.wikidataId, isNull);
    },
  );

  test('a place Nominatim does not know gives empty details', () async {
    transport.handler = osmServices(lookup: const <Object?>[]);

    final details = await nominatim().details('N1', language: 'en');

    expect(details.openingHours, isNull);
    expect(details.phone, isNull);
  });

  test(
    'refuses what is not an OpenStreetMap identifier, without asking',
    () async {
      for (final id in [
        '',
        'W',
        'W0',
        'X12',
        'w12',
        'W12a',
        'N12345678901234567',
      ]) {
        await expectLater(
          nominatim().details(id, language: 'en'),
          throwsArgumentError,
          reason: id,
        );
      }
      expect(transport.requests, isEmpty);
    },
  );

  test('a service without network or busy says so', () async {
    transport.goOffline();
    await expectLater(
      nominatim().details('W477279033', language: 'en'),
      _failure(ServiceFailureKind.noConnection),
    );

    transport.handler = (_) => jsonAnswer(null, status: 503);
    await expectLater(
      nominatim().details('W477279033', language: 'en'),
      _failure(ServiceFailureKind.busy),
    );
  });

  group('reading the tags', () {
    test('contact tags stand in for the plain ones', () {
      final details = parse({
        'contact:phone': '+39 0577 292226',
        'contact:website': 'comune.siena.it',
      });

      expect(details.phone, '+39 0577 292226');
      expect(details.website, 'https://comune.siena.it');
    });

    test('of several websites the first is kept', () {
      expect(
        parse({'website': 'https://www.uffizi.it;https://www.b.it'}).website,
        'https://www.uffizi.it',
      );
    });

    test('a website that is not a web page is dropped', () {
      for (final site in ['javascript:alert(1)', 'ftp://a.it', 'not a site']) {
        expect(parse({'website': site}).website, isNull, reason: site);
      }
    });

    test('a wrong Wikidata identifier is dropped', () {
      for (final id in ['Q0', 'P31', 'Q51252x', 'q51252']) {
        expect(parse({'wikidata': id}).wikidataId, isNull, reason: id);
      }
    });

    test('values too long are dropped', () {
      final details = parse({
        'opening_hours': 'Mo 09:00-10:00; ' * 40,
        'phone': '1' * 101,
      });

      expect(details.openingHours, isNull);
      expect(details.phone, isNull);
    });

    test('an answer that is not a list is a bad answer', () {
      expect(
        () => NominatimPlaceDetails.parse({'error': 'x'}, fetchedAt: now),
        _failure(ServiceFailureKind.badResponse),
      );
    });
  });
}
