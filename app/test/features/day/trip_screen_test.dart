// SPDX-License-Identifier: GPL-3.0-or-later

// The trip screen with its days and stops (S03, S04): every flow on a real
// database in memory, as on a device.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/models/money.dart';
import 'package:itinerea/core/models/stop.dart';
import 'package:itinerea/core/models/time.dart';
import 'package:itinerea/core/models/trip.dart';
import 'package:itinerea/features/day/stop_detail_panel.dart';
import 'package:itinerea/features/day/stop_repository.dart';
import 'package:itinerea/features/trips/trip_plan.dart';
import 'package:itinerea/features/trips/trip_repository.dart';
import 'package:itinerea/features/trips/trip_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

const _phone = Size(390, 844);
const _desktop = Size(1440, 900);

void main() {
  late DataDatabase database;

  setUp(() => database = DataDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<TripRepository> trips() async =>
      TripRepository(await EntityStore.open(database));

  Future<StopRepository> stops() async =>
      StopRepository(await EntityStore.open(database));

  /// Creates a trip of [days] days with the stops given per day, before the
  /// app starts.
  Future<({EntityId trip, List<DaySummary> days})> createTrip({
    int days = 3,
    LocalDate? start,
    List<List<String>> stopsPerDay = const [],
  }) async {
    final repository = await trips();
    final trip = await repository.createTrip(
      TripDraft(
        type: SegmentType.itinerary,
        name: 'Toscana',
        dayCount: days,
        startDate: start,
        timezone: 'Europe/Rome',
        currency: 'EUR',
      ),
    );
    final dayList = await repository.days(trip);
    final stopRepository = await stops();
    for (final (index, names) in stopsPerDay.indexed) {
      for (final name in names) {
        await stopRepository.addStop(
          tripId: trip,
          dayId: dayList[index].id,
          name: name,
        );
      }
    }
    return (trip: trip, days: dayList);
  }

  /// Starts the app on a window of [size] and opens [trip] from the home.
  Future<void> openTrip(
    WidgetTester tester,
    EntityId trip, {
    Size size = _phone,
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    await pumpItinerea(
      tester,
      database: database,
      systemLocale: locale,
      systemBrightness: brightness,
    );
    await tapKey(tester, 'trip-${trip.value}');
    expect(find.byType(TripScreen), findsOneWidget);
  }

  Future<List<String>> storedNames(DaySummary day) async => [
    for (final stop in await (await stops()).stopsOfDay(day.id)) stop.name,
  ];

  /// Names of the stops on screen, top to bottom.
  List<String> shownNames(WidgetTester tester) {
    final rows = find.byWidgetPredicate(
      (widget) =>
          widget is ListTile &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('stop-'),
    );
    final tiles = tester.widgetList<ListTile>(rows).toList()
      ..sort(
        (a, b) => tester
            .getTopLeft(find.byWidget(a))
            .dy
            .compareTo(tester.getTopLeft(find.byWidget(b)).dy),
      );
    return [for (final tile in tiles) (tile.title! as Text).data!];
  }

  String dayTitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('dayTitle'))).data!;

  group('days of a trip', () {
    testWidgets('a trip without dates shows "Day 1", "Day 2"', (tester) async {
      final trip = await createTrip(days: 3);
      await openTrip(tester, trip.trip);

      expect(dayTitle(tester), 'Day 1');
      await tapKey(tester, 'day-3');
      expect(dayTitle(tester), 'Day 3');
    });

    testWidgets('a trip with dates shows the date of each day', (tester) async {
      final trip = await createTrip(days: 2, start: LocalDate(2026, 3, 12));
      await openTrip(tester, trip.trip);

      expect(dayTitle(tester), 'Day 1 · Thu, Mar 12');
      await tapKey(tester, 'day-2');
      expect(dayTitle(tester), 'Day 2 · Fri, Mar 13');
    });
  });

  group('adding a stop (F1.2)', () {
    testWidgets('an empty day invites to add the first stop', (tester) async {
      final trip = await createTrip();
      await openTrip(tester, trip.trip);

      expect(find.text('No stops yet'), findsOneWidget);
      await tapKey(tester, 'addFirstStop');
      await tester.enterText(find.byKey(const Key('newStopName')), 'Uffizi');
      await tapKey(tester, 'newStopAdd');

      expect(shownNames(tester), ['Uffizi']);
      expect(find.text('No stops yet'), findsNothing);
      expect(await storedNames(trip.days[0]), ['Uffizi']);
    });

    testWidgets('"+" adds a stop at the end of the day in two taps', (
      tester,
    ) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi', 'Duomo'],
        ],
      );
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'addStop'); // 1
      await tester.enterText(find.byKey(const Key('newStopName')), 'Pranzo');
      await tapKey(tester, 'newStopAdd'); // 2

      expect(shownNames(tester), ['Uffizi', 'Duomo', 'Pranzo']);
      // A free stop lasts one hour (F1.2).
      final added = (await (await stops()).stopsOfDay(trip.days[0].id)).last;
      expect(added.kind, StopKind.free);
      expect(added.durationMin, 60);
    });

    testWidgets('a stop without a name is not added, and says why', (
      tester,
    ) async {
      final trip = await createTrip();
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'addStop');
      await tester.enterText(find.byKey(const Key('newStopName')), '   ');
      await tapKey(tester, 'newStopAdd');

      expect(find.text('Give the stop a name'), findsOneWidget);
      expect(await storedNames(trip.days[0]), isEmpty);
    });
  });

  group('details of a stop (S04)', () {
    Future<void> openDetails(WidgetTester tester, String name) async {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
      expect(find.byType(StopDetailPanel), findsOneWidget);
    }

    Future<void> submit(WidgetTester tester, String field, String text) async {
      await tester.enterText(find.byKey(Key(field)), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    Future<DayStop> stored(DaySummary day) async =>
        (await (await stops()).stopsOfDay(day.id)).single;

    testWidgets('duration and status are saved at once', (tester) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi'],
        ],
      );
      await openTrip(tester, trip.trip);
      await openDetails(tester, 'Uffizi');

      await tapKey(tester, 'stopLonger');
      await tapKey(tester, 'stopLonger');
      await tapKey(tester, 'stopStatus-visited');

      expect(
        tester.widget<Text>(find.byKey(const Key('stopDurationValue'))).data,
        '1 h 30 min',
      );
      final stop = await stored(trip.days[0]);
      expect(stop.durationMin, 90);
      expect(stop.status, StopStatus.visited);
    });

    testWidgets('name, estimated cost, note and links are saved', (
      tester,
    ) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi'],
        ],
      );
      await openTrip(tester, trip.trip);
      await openDetails(tester, 'Uffizi');

      await submit(tester, 'stopName', 'Galleria degli Uffizi');
      await submit(tester, 'stopCost', '12,50');
      await submit(tester, 'stopNote', 'Ingresso 2');
      await submit(tester, 'stopLinkAdd', 'www.uffizi.it');

      final stop = await stored(trip.days[0]);
      expect(stop.name, 'Galleria degli Uffizi');
      expect(stop.estimatedCost?.amountMinor, 1250);
      expect(stop.estimatedCost?.currency, 'EUR');
      expect(stop.note, 'Ingresso 2');
      expect(stop.links, [Uri.parse('https://www.uffizi.it')]);
      // The cost is labelled as an estimate that stays out of the budget.
      expect(find.text('An estimate: it does not enter the budget.'), findsOne);
      // Saved once, not once for "done" and once more for the lost focus.
      final operations = await (await EntityStore.open(database))
          .pendingOperations();
      expect(
        operations.where((op) => op.fields.containsKey('estimatedCost')),
        hasLength(2), // created empty, then set once
      );
    });

    testWidgets('wrong values are refused and say why', (tester) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi'],
        ],
      );
      await openTrip(tester, trip.trip);
      await openDetails(tester, 'Uffizi');

      await submit(tester, 'stopName', '  ');
      await submit(tester, 'stopCost', '12,5,0');
      await submit(tester, 'stopLinkAdd', 'javascript:alert(1)');

      expect(find.text('Give the stop a name'), findsOneWidget);
      expect(find.text('Not an amount'), findsOneWidget);
      expect(find.text('Not a web address'), findsOneWidget);
      final stop = await stored(trip.days[0]);
      expect(stop.name, 'Uffizi');
      expect(stop.estimatedCost, isNull);
      expect(stop.links, isEmpty);
    });

    testWidgets('an emptied cost is removed', (tester) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi'],
        ],
      );
      final stop = await stored(trip.days[0]);
      await (await stops()).setEstimatedCost(
        stop.stopId,
        const Money(amountMinor: 2500, currency: 'EUR'),
      );
      await openTrip(tester, trip.trip);
      await openDetails(tester, 'Uffizi');

      expect(find.text('25.00'), findsOneWidget);
      await submit(tester, 'stopCost', '');

      expect((await stored(trip.days[0])).estimatedCost, isNull);
    });
  });

  group('order of the stops (F1.2)', () {
    testWidgets('dragging a stop reorders the day, and the order is saved', (
      tester,
    ) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi', 'Pranzo', 'Duomo'],
        ],
      );
      await openTrip(tester, trip.trip);
      final duomo = (await (await stops()).stopsOfDay(trip.days[0].id)).last;

      final handle = find.byKey(Key('drag-${duomo.slotId.value}'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var step = 0; step < 20; step++) {
        await gesture.moveBy(const Offset(0, -12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(shownNames(tester), ['Duomo', 'Uffizi', 'Pranzo']);
      // Saved at once, on the device: no network involved.
      expect(await storedNames(trip.days[0]), ['Duomo', 'Uffizi', 'Pranzo']);
    });

    testWidgets('a long press moves a stop to another day (FL9)', (
      tester,
    ) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi', 'Pranzo'],
          ['Siena'],
        ],
      );
      await openTrip(tester, trip.trip);

      await tester.longPress(find.text('Pranzo')); // 1
      await tester.pumpAndSettle();
      await tapKey(tester, 'menuMoveStop'); // 2
      await tapKey(tester, 'moveToDay-2'); // 3

      expect(shownNames(tester), ['Uffizi']);
      await tapKey(tester, 'day-2');
      expect(shownNames(tester), ['Siena', 'Pranzo']);
      expect(await storedNames(trip.days[1]), ['Siena', 'Pranzo']);
    });

    testWidgets('a stop deleted by mistake comes back with "Restore"', (
      tester,
    ) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi', 'Pranzo', 'Duomo'],
        ],
      );
      await openTrip(tester, trip.trip);

      await tester.longPress(find.text('Pranzo'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'menuDeleteStop');

      expect(shownNames(tester), ['Uffizi', 'Duomo']);
      expect(find.text('"Pranzo" deleted'), findsOneWidget);

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(shownNames(tester), ['Uffizi', 'Pranzo', 'Duomo']);
      expect(await storedNames(trip.days[0]), ['Uffizi', 'Pranzo', 'Duomo']);
    });

    testWidgets('the details offer to delete the stop too', (tester) async {
      final trip = await createTrip(
        stopsPerDay: [
          ['Uffizi', 'Pranzo'],
        ],
      );
      await openTrip(tester, trip.trip);

      await tester.tap(find.text('Pranzo'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'stopDelete');

      expect(find.byType(StopDetailPanel), findsNothing);
      expect(shownNames(tester), ['Uffizi']);
      expect(find.text('"Pranzo" deleted'), findsOneWidget);
    });
  });

  group('kind of trip from a day on (FL8)', () {
    testWidgets('"From here: Roadtrip" in three taps, undone the same way', (
      tester,
    ) async {
      final trip = await createTrip(days: 4);
      await openTrip(tester, trip.trip);
      await tapKey(tester, 'day-2');

      await tapKey(tester, 'dayMenu'); // 1
      await tapKey(tester, 'dayChangeKind'); // 2
      await tapKey(tester, 'roadtripByMotorbike'); // 3

      // Only the days of the roadtrip say so.
      final shown = <int, bool>{};
      for (final day in [1, 2, 3, 4]) {
        await tapKey(tester, 'day-$day');
        shown[day] = find.byKey(const Key('dayRoadtrip')).evaluate().isNotEmpty;
      }
      expect(shown, {1: false, 2: true, 3: true, 4: true});
      expect(find.text('Roadtrip by motorbike'), findsOneWidget);

      await tapKey(tester, 'day-2');
      await tapKey(tester, 'dayMenu');
      expect(find.text('From here: Itinerary'), findsOneWidget);
      await tapKey(tester, 'dayChangeKind');

      expect(find.byKey(const Key('dayRoadtrip')), findsNothing);
      final segments = await (await trips()).segments(trip.trip);
      expect(segments.map((s) => s.type), [SegmentType.itinerary]);
    });
  });

  group('time zone (PRD 8.3)', () {
    testWidgets('a day in another time zone says so in its heading', (
      tester,
    ) async {
      final trip = await createTrip(days: 2);
      await openTrip(tester, trip.trip);
      // Same zone as the device: nothing to say.
      expect(find.byKey(const Key('dayTimezoneNote')), findsNothing);

      await tapKey(tester, 'dayMenu');
      await tapKey(tester, 'dayChangeTimezone');
      await tester.enterText(find.byKey(const Key('timezoneSearch')), 'dublin');
      await tester.pumpAndSettle();
      await tapKey(tester, 'timezone-Europe/Dublin');

      expect(find.text('Times in Europe/Dublin'), findsOneWidget);
      await tapKey(tester, 'day-2');
      expect(find.byKey(const Key('dayTimezoneNote')), findsNothing);
      final days = await (await trips()).days(trip.trip);
      expect(days.map((day) => (day.timezone, day.timezoneSource)), [
        ('Europe/Dublin', TimezoneSource.user),
        ('Europe/Rome', TimezoneSource.device),
      ]);
    });

    testWidgets('the zone of the trip reaches the days not set by hand', (
      tester,
    ) async {
      final trip = await createTrip(days: 2);
      await (await trips()).setDayTimezone(trip.days[1].id, 'Asia/Tokyo');
      await openTrip(tester, trip.trip);

      await tapKey(tester, 'tripMenu');
      await tapKey(tester, 'tripChangeTimezone');
      await tester.enterText(find.byKey(const Key('timezoneSearch')), 'dublin');
      await tester.pumpAndSettle();
      await tapKey(tester, 'timezone-Europe/Dublin');

      expect(find.text('Times in Europe/Dublin'), findsOneWidget);
      await tapKey(tester, 'day-2');
      expect(find.text('Times in Asia/Tokyo'), findsOneWidget);
    });
  });

  group('changing the dates (F1.1)', () {
    Future<void> openEditDates(WidgetTester tester) async {
      await tapKey(tester, 'tripMenu');
      await tapKey(tester, 'tripEditDates');
    }

    testWidgets('a shorter trip with stops asks first: "move" keeps them', (
      tester,
    ) async {
      final trip = await createTrip(
        days: 4,
        stopsPerDay: [
          ['Uffizi'],
          ['Siena'],
          ['Volterra'],
          ['San Gimignano'],
        ],
      );
      await openTrip(tester, trip.trip);
      await openEditDates(tester);

      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'fewerDays');
      await tapKey(tester, 'fewerDays');
      await tapKey(tester, 'datesSave');

      expect(find.text('Stops in the days you are removing'), findsOneWidget);
      expect(
        find.text(
          '2 stops are in the days that will be removed. '
          'What should happen to them?',
        ),
        findsOneWidget,
      );
      await tapKey(tester, 'datesMoveStops');

      expect(find.byType(TripScreen), findsOneWidget);
      expect(find.byKey(const Key('day-3')), findsNothing);
      await tapKey(tester, 'day-2');
      expect(shownNames(tester), ['Siena', 'Volterra', 'San Gimignano']);
    });

    testWidgets('"delete" removes the stops with their days', (tester) async {
      final trip = await createTrip(
        days: 3,
        stopsPerDay: [
          ['Uffizi'],
          [],
          ['Siena'],
        ],
      );
      await openTrip(tester, trip.trip);
      await openEditDates(tester);

      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'fewerDays');
      await tapKey(tester, 'datesSave');
      await tapKey(tester, 'datesDeleteStops');

      expect(find.byKey(const Key('day-3')), findsNothing);
      final days = await (await trips()).days(trip.trip);
      expect(days, hasLength(2));
      expect(await storedNames(days[0]), ['Uffizi']);
      expect(await storedNames(days[1]), isEmpty);
    });

    testWidgets('closing the question changes nothing', (tester) async {
      final trip = await createTrip(
        days: 2,
        stopsPerDay: [
          [],
          ['Siena'],
        ],
      );
      await openTrip(tester, trip.trip);
      await openEditDates(tester);

      await tester.tap(find.text('Number of days only'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'fewerDays');
      await tapKey(tester, 'datesSave');
      await tapKey(tester, 'datesCancel');

      expect(find.byKey(const Key('datesSave')), findsOneWidget);
      expect(await (await trips()).days(trip.trip), hasLength(2));
    });

    testWidgets('dates given later reach every day and keep the stops', (
      tester,
    ) async {
      final trip = await createTrip(
        days: 3,
        stopsPerDay: [
          ['Uffizi'],
          [],
          ['Siena'],
        ],
      );
      await openTrip(tester, trip.trip);
      await openEditDates(tester);

      // "Today" is 10 March 2026 in these tests.
      await tester.tap(find.text('With dates'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'tripStartDate');
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'tripEndDate');
      await tester.tap(find.text('22'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'datesSave');

      expect(dayTitle(tester), 'Day 1 · Fri, Mar 20');
      expect(shownNames(tester), ['Uffizi']);
      await tapKey(tester, 'day-3');
      expect(dayTitle(tester), 'Day 3 · Sun, Mar 22');
      expect(shownNames(tester), ['Siena']);
    });
  });

  group('wide screens', () {
    testWidgets('days, day and details sit side by side', (tester) async {
      final trip = await createTrip(
        days: 2,
        start: LocalDate(2026, 3, 12),
        stopsPerDay: [
          ['Uffizi', 'Duomo'],
        ],
      );
      await openTrip(tester, trip.trip, size: _desktop);

      // The list of days is always visible, with the dates.
      expect(find.text('Day 2 · Fri, Mar 13'), findsOneWidget);
      await tester.tap(find.text('Duomo'));
      await tester.pumpAndSettle();

      // The details open beside the day, not over it.
      expect(find.byType(StopDetailPanel), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        tester.getTopLeft(find.byType(StopDetailPanel)).dx,
        greaterThan(tester.getTopRight(find.text('Duomo').first).dx),
      );
      await tapKey(tester, 'closeStopDetail');
      expect(find.byType(StopDetailPanel), findsNothing);
    });

    testWidgets(
      'a tablet shows the day with its chips and the details beside',
      (tester) async {
        final trip = await createTrip(
          days: 2,
          stopsPerDay: [
            ['Uffizi'],
          ],
        );
        await openTrip(tester, trip.trip, size: const Size(800, 1100));

        // No column of days: the chips choose the day, as on a phone.
        expect(find.byKey(const Key('day-2')), findsOneWidget);
        expect(find.text('Days'), findsNothing);
        await tester.tap(find.text('Uffizi'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);
        final panel = tester.getRect(find.byType(StopDetailPanel));
        expect(panel.left, greaterThanOrEqualTo(400));
        expect(panel.width, greaterThanOrEqualTo(380));
        final button = tester.getRect(find.byKey(const Key('addStop')));
        expect(button.right, lessThanOrEqualTo(400));
      },
    );

    testWidgets('"+" sits at the bottom of the day column', (tester) async {
      final trip = await createTrip(days: 1);
      await openTrip(tester, trip.trip, size: _desktop);

      final button = tester.getRect(find.byKey(const Key('addStop')));
      expect(button.right, lessThanOrEqualTo(221 + 400));
      expect(button.left, greaterThan(221));

      await tapKey(tester, 'addStop');
      await tester.enterText(find.byKey(const Key('newStopName')), 'Uffizi');
      await tapKey(tester, 'newStopAdd');
      expect(shownNames(tester), ['Uffizi']);
    });
  });

  group('every size, both themes, large text', () {
    for (final (name, size) in [
      ('small phone', const Size(320, 640)),
      ('tablet', const Size(800, 1100)),
      ('desktop', _desktop),
    ]) {
      for (final brightness in Brightness.values) {
        testWidgets('$name, ${brightness.name}: a day with stops and details', (
          tester,
        ) async {
          final trip = await createTrip(
            days: 3,
            start: LocalDate(2026, 3, 12),
            stopsPerDay: [
              ['Galleria degli Uffizi', 'Pranzo al Mercato Centrale'],
            ],
          );
          await (await trips()).setDayTimezone(
            trip.days[0].id,
            'Europe/Dublin',
          );
          await (await trips()).changeTypeFromDay(
            trip.trip,
            dayIndex: 1,
            type: SegmentType.roadtrip,
            vehicleKind: VehicleKind.motorbike,
          );
          await openTrip(
            tester,
            trip.trip,
            size: size,
            locale: const Locale('it'),
            brightness: brightness,
            textScale: 2,
          );
          expect(tester.takeException(), isNull);

          // The day scrolls as a whole: on a small phone with large text
          // the second stop is below the fold.
          await tester.ensureVisible(
            find.text('Pranzo al Mercato Centrale', skipOffstage: false),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Pranzo al Mercato Centrale'));
          await tester.pumpAndSettle();
          expect(find.byType(StopDetailPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
