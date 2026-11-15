// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/models/time.dart';
import 'package:itinerea/core/models/trip.dart';
import 'package:itinerea/features/trips/new_trip_screen.dart';
import 'package:itinerea/features/trips/timezone_picker_screen.dart';
import 'package:itinerea/features/trips/trip_repository.dart';
import 'package:itinerea/features/trips/trip_screen.dart';
import 'package:itinerea/features/trips/trips_home_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

void main() {
  late DataDatabase database;

  setUp(() => database = DataDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<TripRepository> repository() async =>
      TripRepository(await EntityStore.open(database));

  /// Opens the app on its database and the "new trip" steps from the home.
  Future<void> openNewTrip(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await pumpItinerea(tester, database: database, systemLocale: locale);
    await tapKey(tester, 'createFirstTrip');
    expect(find.byType(NewTripScreen), findsOneWidget);
  }

  Future<void> pickDay(WidgetTester tester, String tile, String day) async {
    await tapKey(tester, tile);
    await tester.tap(find.text(day));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('new trip (F1.1)', () {
    testWidgets('with only a number of days, in three steps', (tester) async {
      await openNewTrip(tester);

      // Step 1: the kind. Itinerary is already selected.
      expect(find.text('Step 1 of 3'), findsOneWidget);
      await tapKey(tester, 'newTripNext');

      // Step 2: name and number of days.
      await tester.enterText(find.byKey(const Key('tripName')), 'Giappone');
      await tester.enterText(
        find.byKey(const Key('tripDestinations')),
        'Tokyo, Kyoto',
      );
      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'moreDays');
      await tapKey(tester, 'moreDays');
      expect(find.text('5 days'), findsOneWidget);
      await tapKey(tester, 'newTripNext');

      // Step 3: places and time zone. Nothing is mandatory.
      expect(find.text('Step 3 of 3'), findsOneWidget);
      await tapKey(tester, 'newTripCreate');

      // The new trip opens on its first day.
      expect(find.byType(TripScreen), findsOneWidget);
      expect(find.byType(NewTripScreen), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('dayTitle'))).data,
        'Day 1',
      );

      // Back on the home, the trip is there, without dates.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TripsHomeScreen), findsOneWidget);
      expect(find.text('Giappone'), findsOneWidget);
      expect(find.text('Without dates'), findsOneWidget);
      expect(
        find.text('5 days, dates to decide · Tokyo, Kyoto'),
        findsOneWidget,
      );

      final trips = await (await repository()).trips();
      expect(trips.single.dayCount, 5);
      expect(trips.single.startDate, isNull);
      expect(await (await repository()).days(trips.single.id), hasLength(5));
    });

    testWidgets('with dates: every day gets its date', (tester) async {
      // "Today" is 10 March 2026 in these tests.
      await openNewTrip(tester);
      await tapKey(tester, 'newTripNext');
      await tester.enterText(find.byKey(const Key('tripName')), 'Toscana');

      await pickDay(tester, 'tripStartDate', '12');
      await pickDay(tester, 'tripEndDate', '15');
      expect(find.text('4 days'), findsOneWidget);
      await tapKey(tester, 'newTripNext');
      await tapKey(tester, 'newTripCreate');

      expect(find.byType(TripScreen), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('dayTitle'))).data,
        'Day 1 · Thu, Mar 12',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Mar 12, 2026 – Mar 15, 2026'), findsOneWidget);
      final repo = await repository();
      final trip = (await repo.trips()).single;
      expect(trip.startDate, LocalDate(2026, 3, 12));
      expect(trip.endDate, LocalDate(2026, 3, 15));
      expect((await repo.days(trip.id)).map((day) => day.date), [
        LocalDate(2026, 3, 12),
        LocalDate(2026, 3, 13),
        LocalDate(2026, 3, 14),
        LocalDate(2026, 3, 15),
      ]);
    });

    testWidgets('choosing only the first day makes a one-day trip', (
      tester,
    ) async {
      await openNewTrip(tester);
      await tapKey(tester, 'newTripNext');
      await tester.enterText(find.byKey(const Key('tripName')), 'Day out');

      await pickDay(tester, 'tripStartDate', '20');

      expect(find.text('1 day'), findsOneWidget);
    });

    testWidgets('a roadtrip by motorbike is saved as such', (tester) async {
      await openNewTrip(tester);

      await tapKey(tester, 'kindRoadtrip');
      await tester.tap(find.text('Motorbike'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'newTripNext');
      await tester.enterText(find.byKey(const Key('tripName')), 'Dolomiti');
      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'newTripNext');
      await tapKey(tester, 'newTripCreate');

      final repo = await repository();
      final segments = await repo.segments((await repo.trips()).single.id);
      expect(segments.single.type, SegmentType.roadtrip);
      expect(segments.single.vehicleKind, VehicleKind.motorbike);
    });

    testWidgets('the vehicle is asked only for a roadtrip', (tester) async {
      await openNewTrip(tester);

      expect(find.byKey(const Key('vehicleSelector')), findsNothing);
      await tapKey(tester, 'kindRoadtrip');
      expect(find.byKey(const Key('vehicleSelector')), findsOneWidget);
      await tapKey(tester, 'kindItinerary');
      expect(find.byKey(const Key('vehicleSelector')), findsNothing);
    });

    testWidgets('without a name it does not go on, and says why', (
      tester,
    ) async {
      await openNewTrip(tester);
      await tapKey(tester, 'newTripNext');
      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();

      // No error before the user tries to go on.
      expect(find.text('Give the trip a name'), findsNothing);
      await tapKey(tester, 'newTripNext');

      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Give the trip a name'), findsOneWidget);
    });

    testWidgets('with dates selected but missing it does not go on', (
      tester,
    ) async {
      await openNewTrip(tester);
      await tapKey(tester, 'newTripNext');
      await tester.enterText(find.byKey(const Key('tripName')), 'Toscana');

      await tapKey(tester, 'newTripNext');

      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Choose the first and the last day'), findsOneWidget);
    });

    testWidgets('"Back" keeps what was typed', (tester) async {
      await openNewTrip(tester);
      await tapKey(tester, 'newTripNext');
      await tester.enterText(find.byKey(const Key('tripName')), 'Toscana');
      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'newTripNext');

      await tapKey(tester, 'newTripBack');

      expect(find.text('Toscana'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
    });

    testWidgets('the return place is asked only when it differs', (
      tester,
    ) async {
      await openNewTrip(tester);
      await tapKey(tester, 'newTripNext');
      await tester.enterText(find.byKey(const Key('tripName')), 'Toscana');
      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'newTripNext');

      expect(find.byKey(const Key('tripReturn')), findsNothing);
      await tapKey(tester, 'returnSamePlace');

      expect(find.byKey(const Key('tripReturn')), findsOneWidget);
    });
  });

  group('time zone of a new trip (PRD 8.3)', () {
    Future<void> reachLastStep(WidgetTester tester) async {
      await openNewTrip(tester);
      await tapKey(tester, 'newTripNext');
      await tester.enterText(find.byKey(const Key('tripName')), 'Irlanda');
      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'newTripNext');
    }

    testWidgets('starts as the zone of the device, and says so', (
      tester,
    ) async {
      await reachLastStep(tester);

      expect(find.text('Time zone: Europe/Rome'), findsOneWidget);
      expect(find.textContaining('From this device'), findsOneWidget);
      await tapKey(tester, 'newTripCreate');

      final trip = (await (await repository()).trips()).single;
      expect(trip.timezone, 'Europe/Rome');
      expect(trip.timezoneSource, TimezoneSource.device);
    });

    testWidgets('can be chosen by hand, and is saved as chosen', (
      tester,
    ) async {
      await reachLastStep(tester);

      await tapKey(tester, 'changeTimezone');
      expect(find.byType(TimezonePickerScreen), findsOneWidget);
      await tester.enterText(find.byKey(const Key('timezoneSearch')), 'dublin');
      await tester.pumpAndSettle();
      await tapKey(tester, 'timezone-Europe/Dublin');

      expect(find.text('Time zone: Europe/Dublin'), findsOneWidget);
      expect(find.text('Chosen by you'), findsOneWidget);
      await tapKey(tester, 'newTripCreate');

      final repo = await repository();
      final trip = (await repo.trips()).single;
      expect(trip.timezone, 'Europe/Dublin');
      expect(trip.timezoneSource, TimezoneSource.user);
      expect(
        (await repo.days(trip.id))
            .every((day) => day.timezoneSource == TimezoneSource.user),
        isTrue,
      );
    });

    testWidgets('the list is searched by words, and says when it is empty', (
      tester,
    ) async {
      await reachLastStep(tester);
      await tapKey(tester, 'changeTimezone');

      await tester.enterText(
        find.byKey(const Key('timezoneSearch')),
        'new york',
      );
      await tester.pumpAndSettle();
      expect(find.text('America/New York'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('timezoneSearch')),
        'atlantis',
      );
      await tester.pumpAndSettle();
      expect(find.text('No time zone found'), findsOneWidget);
    });
  });

  group('new trip on a small phone', () {
    testWidgets('every step fits in Italian with large system text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);

      await openNewTrip(tester, locale: const Locale('it'));
      await tapKey(tester, 'kindRoadtrip');
      expect(tester.takeException(), isNull);

      await tapKey(tester, 'newTripNext');
      await tester.enterText(find.byKey(const Key('tripName')), 'Toscana');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Solo i giorni'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tapKey(tester, 'newTripNext');
      await tapKey(tester, 'returnSamePlace');
      expect(tester.takeException(), isNull);
      expect(find.text('Passo 3 di 3'), findsOneWidget);
    });
  });

  group('home with several trips', () {
    testWidgets('shows the current trip first, then the others by date', (
      tester,
    ) async {
      TripSummary trip(String name, {LocalDate? start, int days = 3}) =>
          TripSummary(
            id: EntityId.generate(),
            name: name,
            startDate: start,
            dayCount: days,
          );

      await pumpItinerea(
        tester,
        today: LocalDate(2026, 3, 10),
        trips: [
          trip('Past, older', start: LocalDate(2025, 6, 1)),
          trip('Someday'),
          trip('Upcoming, later', start: LocalDate(2026, 8, 1)),
          trip('Happening now', start: LocalDate(2026, 3, 9)),
          trip('Past, recent', start: LocalDate(2026, 1, 5)),
          trip('Upcoming, soon', start: LocalDate(2026, 4, 2)),
        ],
      );

      final titles = [
        for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
          (tile.title! as Text).data,
      ];
      expect(titles, [
        'Happening now',
        'Upcoming, soon',
        'Upcoming, later',
        'Someday',
        'Past, recent',
        'Past, older',
      ]);
      for (final heading in ['Now', 'Upcoming', 'Without dates', 'Past']) {
        expect(find.text(heading), findsOneWidget);
      }
    });
  });
}
