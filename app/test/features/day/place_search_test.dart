// SPDX-License-Identifier: GPL-3.0-or-later

// Adding a stop by searching its place (F1.2, flow FL1), and the opening
// hours and contacts of its place in the details of the stop. The whole app
// on a database in memory; Photon and Nominatim are answered by a fake.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/models/place.dart';
import 'package:itinerea/core/models/stop.dart';
import 'package:itinerea/core/models/trip.dart';
import 'package:itinerea/features/day/stop_detail_panel.dart';
import 'package:itinerea/features/day/stop_repository.dart';
import 'package:itinerea/features/trips/trip_plan.dart';
import 'package:itinerea/features/trips/trip_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_transport.dart';
import '../../support/osm_samples.dart';
import '../../support/test_app.dart';

const _hours = 'Tu-Su 08:15-18:30; Mo off; Jan 1 off; Dec 25 off';

void main() {
  late DataDatabase database;
  late FakeTransport transport;

  setUp(() {
    database = DataDatabase(NativeDatabase.memory());
    transport = FakeTransport(osmServices());
  });
  tearDown(() => database.close());

  Future<StopRepository> stops() async =>
      StopRepository(await EntityStore.open(database));

  /// A trip of two days; the first has a stop at each place given.
  Future<({EntityId trip, DaySummary day})> createTrip({
    List<PlaceSnapshot> at = const [],
  }) async {
    final trips = TripRepository(await EntityStore.open(database));
    final trip = await trips.createTrip(
      const TripDraft(
        type: SegmentType.itinerary,
        name: 'Toscana',
        dayCount: 2,
        timezone: 'Europe/Rome',
        currency: 'EUR',
      ),
    );
    final day = (await trips.days(trip)).first;
    for (final place in at) {
      await (await stops()).addStop(
        tripId: trip,
        dayId: day.id,
        name: place.name,
        place: place,
      );
    }
    return (trip: trip, day: day);
  }

  Future<void> openTrip(
    WidgetTester tester,
    EntityId trip, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpItinerea(
      tester,
      database: database,
      transport: transport,
      systemLocale: locale,
    );
    await tapKey(tester, 'trip-${trip.value}');
  }

  /// Types [text] in the sheet and waits for the pause after the last key.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('newStopName')), text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Future<DayStop> stored(DaySummary day) async =>
      (await (await stops()).stopsOfDay(day.id)).single;

  Future<void> openDetails(WidgetTester tester, String name) async {
    await tester.tap(find.text(name).first);
    await tester.pumpAndSettle();
    expect(find.byType(StopDetailPanel), findsOneWidget);
  }

  String field(WidgetTester tester, String key) => tester
      .widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  group('searching a place (FL1)', () {
    testWidgets('a place found by name is added in two taps', (tester) async {
      final trip = await createTrip();
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'addFirstStop'); // 1
      await type(tester, 'Uffizi');
      expect(find.text('Galleria degli Uffizi'), findsOneWidget);
      expect(find.text('Via dei Girolami, Firenze, Italia'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      await tapKey(tester, 'placeSuggestion-0'); // 2
      await tester.pumpAndSettle();

      final stop = await stored(trip.day);
      expect(stop.name, 'Galleria degli Uffizi');
      expect(stop.kind, StopKind.place);
      expect(stop.place!.osmId, 'W477279033');
      expect(stop.place!.coordinates!.lat, 43.7683129);
      expect(stop.place!.address, 'Via dei Girolami, Firenze, Italia');
      // Hours and contacts came with one lookup, after the choice.
      expect(stop.place!.openingHours, _hours);
      expect(stop.place!.phone, '+39 055 294883');
      expect(stop.place!.website, 'https://www.uffizi.it');
      expect(transport.requests.map((uri) => uri.path), ['/api/', '/lookup']);
    });

    testWidgets('waits for a pause in typing and for three letters', (
      tester,
    ) async {
      final trip = await createTrip();
      await openTrip(tester, trip.trip);
      await tapKey(tester, 'addFirstStop');

      await tester.enterText(find.byKey(const Key('newStopName')), 'Uf');
      await tester.pump(const Duration(seconds: 1));
      expect(transport.requests, isEmpty);

      for (final text in ['Uff', 'Uffi', 'Uffiz', 'Uffizi']) {
        await tester.enterText(find.byKey(const Key('newStopName')), text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(transport.requests.map((uri) => uri.queryParameters['q']), [
        'Uffizi',
      ]);
    });

    testWidgets('prefers places near the stops of the day', (tester) async {
      final trip = await createTrip(
        at: [
          const PlaceSnapshot(
            name: 'Duomo di Firenze',
            coordinates: Coordinates(lat: 43.773145, lon: 11.255963),
          ),
        ],
      );
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'addStop');
      await type(tester, 'Uffizi');

      final query = transport.requests.single.queryParameters;
      expect(query['lat'], '43.77');
      expect(query['lon'], '11.26');
    });

    testWidgets('offline, the sheet says so and the name alone is added', (
      tester,
    ) async {
      transport.goOffline();
      final trip = await createTrip();
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'addFirstStop');
      await type(tester, 'Uffizi');
      expect(
        find.text(
          'No connection: places cannot be searched. You can add just the '
          'name.',
        ),
        findsOneWidget,
      );
      await tapKey(tester, 'newStopAdd');

      final stop = await stored(trip.day);
      expect(stop.name, 'Uffizi');
      expect(stop.kind, StopKind.free);
      expect(stop.place, isNull);
    });

    testWidgets('a busy service can be tried again', (tester) async {
      transport.handler = (_) => jsonAnswer(null, status: 429);
      final trip = await createTrip();
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'addFirstStop');
      await type(tester, 'Uffizi');
      expect(
        find.text(
          'The search service is busy. Try again in a moment, or add just '
          'the name.',
        ),
        findsOneWidget,
      );
      transport.handler = osmServices();
      await tapKey(tester, 'placeSearchRetry');

      expect(find.text('Galleria degli Uffizi'), findsOneWidget);
      expect(find.byKey(const Key('placeSearchMessage')), findsNothing);
    });

    testWidgets('nothing found is said plainly', (tester) async {
      transport.handler = osmServices(
        search: const {'type': 'FeatureCollection', 'features': <Object?>[]},
      );
      final trip = await createTrip();
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'addFirstStop');
      await type(tester, 'Qwxyz');

      expect(
        find.text('No places found. You can add just the name.'),
        findsOneWidget,
      );
    });

    testWidgets('a search service that blocks the app leaves a free stop', (
      tester,
    ) async {
      transport.handler = (_) => jsonAnswer({'error': 'blocked'}, status: 403);
      final trip = await createTrip();
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'addFirstStop');
      await type(tester, 'Uffizi');
      expect(
        find.text(
          'I could not search places. Try again in a moment, or add just '
          'the name.',
        ),
        findsOneWidget,
      );
      await tapKey(tester, 'newStopAdd');
      await openDetails(tester, 'Uffizi');
      await tester.enterText(
        find.byKey(const Key('stopName')),
        'Galleria degli Uffizi',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final stop = await stored(trip.day);
      expect(stop.kind, StopKind.free);
      expect(stop.name, 'Galleria degli Uffizi');
      expect(tester.takeException(), isNull);
    });

    testWidgets('in Italian the sheet speaks Italian and asks local names', (
      tester,
    ) async {
      final trip = await createTrip();
      await openTrip(tester, trip.trip, locale: const Locale('it'));

      await tapKey(tester, 'addFirstStop');
      await type(tester, 'Uffizi');

      expect(transport.requests.single.queryParameters['lang'], 'default');
      expect(find.text('Aggiungi solo il nome'), findsOneWidget);
      expect(find.text('Luogo o nome'), findsOneWidget);
    });
  });

  group('opening hours and contacts in the details of a stop', () {
    testWidgets('come from OpenStreetMap, with the date of the download', (
      tester,
    ) async {
      final trip = await createTrip();
      await openTrip(tester, trip.trip);
      await tapKey(tester, 'addFirstStop');
      await type(tester, 'Uffizi');
      await tapKey(tester, 'placeSuggestion-0');
      await tester.pumpAndSettle();

      await openDetails(tester, 'Galleria degli Uffizi');

      expect(find.byKey(const Key('stopAddress')), findsOneWidget);
      expect(field(tester, 'stopOpeningHours'), _hours);
      expect(field(tester, 'stopPhone'), '+39 055 294883');
      expect(field(tester, 'stopWebsite'), 'https://www.uffizi.it');
      expect(
        find.textContaining('From OpenStreetMap, updated on'),
        findsOneWidget,
      );
      // Downloaded a moment ago: asking again today is not offered.
      expect(find.byKey(const Key('placeDetailsRefresh')), findsNothing);
      expect(transport.requests.map((uri) => uri.path), ['/api/', '/lookup']);
    });

    testWidgets('a place without them leaves the fields empty and editable', (
      tester,
    ) async {
      transport.handler = osmServices(lookup: nominatimNothing);
      final trip = await createTrip();
      await openTrip(tester, trip.trip);
      await tapKey(tester, 'addFirstStop');
      await type(tester, 'Uffizi');
      await tapKey(tester, 'placeSuggestion-2');
      await tester.pumpAndSettle();

      await openDetails(tester, 'Piazzale degli Uffizi');
      expect(field(tester, 'stopOpeningHours'), isEmpty);
      expect(field(tester, 'stopPhone'), isEmpty);
      expect(field(tester, 'stopWebsite'), isEmpty);
      expect(find.byKey(const Key('placeDetailsMessage')), findsNothing);

      await tester.enterText(find.byKey(const Key('stopPhone')), '055 1234');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect((await stored(trip.day)).place!.phone, '055 1234');
    });

    testWidgets('a details service that blocks leaves the place editable', (
      tester,
    ) async {
      final services = osmServices();
      transport.handler = (uri) => uri.path == '/lookup'
          ? jsonAnswer({'error': 'blocked'}, status: 403)
          : services(uri);
      final trip = await createTrip();
      await openTrip(tester, trip.trip);
      await tapKey(tester, 'addFirstStop');
      await type(tester, 'Uffizi');
      await tapKey(tester, 'placeSuggestion-0');
      await tester.pumpAndSettle();

      await openDetails(tester, 'Galleria degli Uffizi');
      expect(field(tester, 'stopOpeningHours'), isEmpty);
      expect(find.byKey(const Key('placeDetailsMessage')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('stopPhone')),
        '+39 055 294883',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final stop = await stored(trip.day);
      expect(stop.kind, StopKind.place);
      expect(stop.place!.osmId, 'W477279033');
      expect(stop.place!.phone, '+39 055 294883');
      expect(transport.requests.where((uri) => uri.path == '/lookup'), [
        isA<Uri>(),
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a saved place is never asked again on its own', (
      tester,
    ) async {
      final trip = await createTrip(
        at: [
          const PlaceSnapshot(
            name: 'Galleria degli Uffizi',
            coordinates: Coordinates(lat: 43.7683, lon: 11.2558),
            osmId: 'W477279033',
          ),
        ],
      );
      await openTrip(tester, trip.trip);

      await openDetails(tester, 'Galleria degli Uffizi');
      await tapKey(tester, 'closeStopDetail');
      await openDetails(tester, 'Galleria degli Uffizi');

      // Only "Update from OpenStreetMap" would ask (PRD 5.6, DECISIONS).
      expect(transport.requests, isEmpty);
      expect(find.byKey(const Key('placeDetailsRefresh')), findsOneWidget);
    });

    testWidgets('an update keeps what the user wrote', (tester) async {
      final trip = await createTrip(
        at: [
          const PlaceSnapshot(
            name: 'Galleria degli Uffizi',
            coordinates: Coordinates(lat: 43.7683, lon: 11.2558),
            osmId: 'W477279033',
            phone: '+39 333 1234567',
          ),
        ],
      );
      await openTrip(tester, trip.trip);
      await openDetails(tester, 'Galleria degli Uffizi');

      await tapKey(tester, 'placeDetailsRefresh');

      final place = (await stored(trip.day)).place!;
      expect(place.phone, '+39 333 1234567');
      expect(place.openingHours, _hours);
      expect(field(tester, 'stopOpeningHours'), _hours);
      expect(
        transport.requests.single.queryParameters['osm_ids'],
        'W477279033',
      );
    });

    testWidgets('offline, the update says so and changes nothing', (
      tester,
    ) async {
      transport.goOffline();
      final trip = await createTrip(
        at: [
          const PlaceSnapshot(
            name: 'Galleria degli Uffizi',
            osmId: 'W477279033',
            openingHours: 'Tu-Su 08:15-18:30',
          ),
        ],
      );
      await openTrip(tester, trip.trip);
      await openDetails(tester, 'Galleria degli Uffizi');

      await tapKey(tester, 'placeDetailsRefresh');

      expect(
        find.text('No connection: hours and contacts cannot be downloaded.'),
        findsOneWidget,
      );
      expect((await stored(trip.day)).place!.openingHours, 'Tu-Su 08:15-18:30');
    });

    testWidgets('a free stop has none of them', (tester) async {
      final trip = await createTrip();
      await (await stops()).addStop(
        tripId: trip.trip,
        dayId: trip.day.id,
        name: 'Pranzo',
      );
      await openTrip(tester, trip.trip);

      await openDetails(tester, 'Pranzo');

      expect(find.byKey(const Key('stopOpeningHours')), findsNothing);
      expect(find.byKey(const Key('placeDetailsRefresh')), findsNothing);
    });
  });
}
