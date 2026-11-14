// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/database_providers.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/entity_kinds.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/theme/window_size.dart';
import 'package:itinerea/features/settings/settings_screen.dart';
import 'package:itinerea/features/trips/new_trip_screen.dart';
import 'package:itinerea/features/trips/trip_list.dart';
import 'package:itinerea/features/trips/trips_home_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'support/test_app.dart';

void main() {
  group('home without trips', () {
    testWidgets('invites to create the first trip, with no login', (
      tester,
    ) async {
      await pumpItinerea(tester);

      expect(find.byType(TripsHomeScreen), findsOneWidget);
      expect(find.text('No trips yet'), findsOneWidget);
      expect(find.byKey(const Key('createFirstTrip')), findsOneWidget);
      expect(find.byKey(const Key('newTrip')), findsNothing);
    });

    testWidgets('is translated', (tester) async {
      await pumpItinerea(tester, systemLocale: const Locale('it'));

      expect(find.text('Viaggi'), findsOneWidget);
      expect(find.text('Nessun viaggio'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Nuovo viaggio'),
        findsOneWidget,
      );
    });

    testWidgets('one tap leads to the creation of a trip', (tester) async {
      await pumpItinerea(tester);

      await tester.tap(find.byKey(const Key('createFirstTrip')));
      await tester.pumpAndSettle();

      expect(find.byType(NewTripScreen), findsOneWidget);
    });
  });

  group('home with trips', () {
    final trips = [
      TripSummary(id: EntityId.generate(), name: 'Toscana in moto'),
      TripSummary(id: EntityId.generate(), name: 'Giappone'),
    ];

    testWidgets('lists them and offers a button to add one', (tester) async {
      await pumpItinerea(tester, trips: trips);

      expect(find.text('Toscana in moto'), findsOneWidget);
      expect(find.text('Giappone'), findsOneWidget);
      expect(find.text('No trips yet'), findsNothing);
      expect(find.byKey(const Key('newTrip')), findsOneWidget);
    });

    testWidgets('each row is tall enough to be tapped comfortably', (
      tester,
    ) async {
      await pumpItinerea(tester, trips: trips);

      for (final row in tester.widgetList<ListTile>(find.byType(ListTile))) {
        expect(
          tester.getSize(find.byWidget(row)).height,
          greaterThanOrEqualTo(56),
        );
      }
    });
  });

  group('home when the data cannot be opened', () {
    testWidgets('says so in plain words and offers to try again', (
      tester,
    ) async {
      var attempts = 0;
      await pumpItinerea(
        tester,
        loadTrips: () async {
          attempts++;
          if (attempts == 1) {
            throw StateError('SqliteException(14): cannot open');
          }
          return [TripSummary(id: EntityId.generate(), name: 'Giappone')];
        },
      );

      expect(
        find.text('The app could not open its data on this device.'),
        findsOneWidget,
      );
      // No technical detail reaches the user.
      expect(find.textContaining('Sqlite'), findsNothing);

      await tester.tap(find.byKey(const Key('retryOpenData')));
      await tester.pumpAndSettle();

      expect(find.text('Giappone'), findsOneWidget);
    });
  });

  group('home on every screen', () {
    for (final (name, size) in [
      ('small phone', const Size(320, 568)),
      ('tablet', const Size(800, 1100)),
      ('desktop', const Size(1440, 900)),
    ]) {
      for (final brightness in Brightness.values) {
        testWidgets('fits a $name in ${brightness.name} theme, large text', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.reset);

          await pumpItinerea(
            tester,
            systemLocale: const Locale('it'),
            systemBrightness: brightness,
          );

          expect(tester.takeException(), isNull);
          expect(
            Theme.of(tester.element(find.byType(TripsHomeScreen))).brightness,
            brightness,
          );
        });
      }
    }

    testWidgets('the settings are one tap away', (tester) async {
      await pumpItinerea(tester);

      await openSettings(tester);

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  test('window sizes follow the breakpoints of the design', () {
    expect(WindowSize.forWidth(320), WindowSize.compact);
    expect(WindowSize.forWidth(599), WindowSize.compact);
    expect(WindowSize.forWidth(600), WindowSize.medium);
    expect(WindowSize.forWidth(1023), WindowSize.medium);
    expect(WindowSize.forWidth(1024), WindowSize.expanded);
    expect(WindowSize.compact.margin, 16);
    expect(WindowSize.expanded.margin, 24);
  });

  group('trips read from the database', () {
    test('are listed by name, without the deleted ones', () async {
      final database = DataDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = await EntityStore.open(database);
      Future<EntityId> create(String name) async {
        final id = EntityId.generate();
        await store.create(
          entity: EntityKinds.trip,
          id: id,
          tripId: id,
          fields: {'name': name},
        );
        return id;
      }

      await create('toscana in moto');
      await create('Giappone');
      await store.delete(await create('Cancelled trip'));
      final container = ProviderContainer(
        overrides: [dataDatabaseProvider.overrideWith((ref) => database)],
      );
      addTearDown(container.dispose);

      final trips = await container.read(tripSummariesProvider.future);

      expect(trips.map((trip) => trip.name), ['Giappone', 'toscana in moto']);
    });
  });
}
