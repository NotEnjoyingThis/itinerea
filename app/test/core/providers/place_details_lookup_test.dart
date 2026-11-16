// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/cache_database.dart';
import 'package:itinerea/core/database/cache_store.dart';
import 'package:itinerea/core/models/place.dart';
import 'package:itinerea/core/net/http_transport.dart';
import 'package:itinerea/core/net/throttle.dart';
import 'package:itinerea/core/providers/nominatim_details.dart';
import 'package:itinerea/core/providers/place_details_lookup.dart';

import '../../support/fake_transport.dart';
import '../../support/osm_samples.dart';

void main() {
  const uffizi = 'W477279033';
  late DateTime clock;
  late CacheDatabase db;
  late FakeTransport transport;
  late PlaceDetailsLookup lookup;

  setUp(() {
    clock = DateTime.utc(2026, 11, 16, 10);
    db = CacheDatabase(NativeDatabase.memory());
    transport = FakeTransport(osmServices());
    lookup = PlaceDetailsLookup(
      NominatimPlaceDetails(
        transport: transport,
        throttle: Throttle(Duration.zero),
        now: () => clock,
      ),
      CacheStore(db),
      now: () => clock,
    );
  });

  tearDown(() => db.close());

  Future<({PlaceDetails details, PlaceDetails? previous})> load({
    bool refresh = false,
  }) => lookup.load(uffizi, language: 'it', refresh: refresh);

  test('the first time the service is asked and the answer kept', () async {
    final (:details, :previous) = await load();

    expect(details.phone, '+39 055 294883');
    expect(previous, isNull);
    expect(transport.requests, hasLength(1));
    final kept = await lookup.cached(uffizi);
    expect(kept!.phone, '+39 055 294883');
    expect(kept.fetchedAt, clock);
  });

  test('for 30 days the place is not asked again, also offline', () async {
    await load();
    transport.goOffline();
    clock = clock.add(const Duration(days: 29));

    final (:details, :previous) = await load();

    expect(details.phone, '+39 055 294883');
    expect(previous?.fetchedAt, details.fetchedAt);
    expect(transport.requests, hasLength(1));
    expect(lookup.isOld(details), isFalse);
  });

  test('after 30 days choosing the place asks again', () async {
    final first = (await load()).details;
    clock = clock.add(const Duration(days: 31));

    expect(lookup.isOld(first), isTrue);
    final (:details, :previous) = await load();

    expect(transport.requests, hasLength(2));
    expect(previous?.fetchedAt, first.fetchedAt);
    expect(details.fetchedAt, clock);
  });

  test('the user can refresh, but not twice in a day', () async {
    final first = (await load()).details;

    clock = clock.add(const Duration(hours: 3));
    expect(lookup.canRefresh(first), isFalse);
    await load(refresh: true);
    expect(transport.requests, hasLength(1));

    clock = clock.add(const Duration(hours: 22));
    expect(lookup.canRefresh(first), isTrue);
    await load(refresh: true);
    expect(transport.requests, hasLength(2));
    expect(lookup.canRefresh(null), isTrue, reason: 'never downloaded');
  });

  test('two loads at the same time send one request', () async {
    final answers = await Future.wait([load(), load()]);

    expect(transport.requests, hasLength(1));
    expect(answers[1].details.phone, answers[0].details.phone);
  });

  test('a failure keeps nothing', () async {
    transport.goOffline();

    await expectLater(load(), throwsA(isA<ServiceFailure>()));

    expect(await lookup.cached(uffizi), isNull);
    transport.handler = osmServices();
    expect((await load()).details.phone, '+39 055 294883');
    expect(transport.requests, hasLength(2), reason: 'asked again');
  });

  test('a download dated in the future counts as old', () async {
    await CacheStore(db).write(
      PlaceDetailsLookup.cacheKind,
      uffizi,
      PlaceDetails(
        fetchedAt: clock.add(const Duration(days: 2)),
        phone: '000',
      ).toJson(),
      fetchedAt: clock.add(const Duration(days: 2)),
    );

    final (:details, previous: _) = await load();

    expect(details.phone, '+39 055 294883');
    expect(transport.requests, hasLength(1));
  });

  group('CacheStore', () {
    test('keeps a value by kind and key, and replaces it', () async {
      final store = CacheStore(db);

      await store.write('kind', 'a', {'n': 1}, fetchedAt: clock);
      await store.write('kind', 'a', {'n': 2}, fetchedAt: clock);
      await store.write('other', 'a', [3], fetchedAt: clock);

      expect((await store.read('kind', 'a'))!.value, {'n': 2});
      expect((await store.read('other', 'a'))!.value, [3]);
      expect((await store.read('kind', 'a'))!.fetchedAt, clock);
      expect(await store.read('kind', 'b'), isNull);
    });

    test('a value that cannot be read counts as missing', () async {
      await db
          .into(db.cacheRows)
          .insert(
            CacheRowsCompanion.insert(
              kind: PlaceDetailsLookup.cacheKind,
              cacheKey: 'N1',
              value: '{not json',
              fetchedAtMillis: 0,
            ),
          );
      await CacheStore(db)
          .write(PlaceDetailsLookup.cacheKind, 'N2', [1, 2], fetchedAt: clock);

      expect(await lookup.cached('N1'), isNull);
      expect(await lookup.cached('N2'), isNull);
    });
  });
}
