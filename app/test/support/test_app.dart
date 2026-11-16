// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/app.dart';
import 'package:itinerea/core/database/cache_database.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/database_providers.dart';
import 'package:itinerea/core/models/time.dart';
import 'package:itinerea/core/net/http_transport.dart';
import 'package:itinerea/core/providers/service_providers.dart';
import 'package:itinerea/core/time/timezones.dart';
import 'package:itinerea/features/scaffold/scaffold_catalog_screen.dart';
import 'package:itinerea/features/trips/trip_list.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_transport.dart';

/// Starts the whole app for a widget test.
///
/// With [database] the app reads and writes that database, as on a device.
/// Otherwise it shows the [trips] given, or what [loadTrips] returns (it may
/// throw, to show the error state).
///
/// External services answer through [transport]; without it the app is
/// offline. The cache is a database in memory: never the network, never
/// the disk.
Future<void> pumpItinerea(
  WidgetTester tester, {
  Locale systemLocale = const Locale('en'),
  Brightness systemBrightness = Brightness.light,
  List<TripSummary> trips = const [],
  Future<List<TripSummary>> Function()? loadTrips,
  DataDatabase? database,
  HttpTransport? transport,
  LocalDate? today,
  String deviceTimezone = 'Europe/Rome',
  bool scaffoldCatalog = false,
}) async {
  tester.platformDispatcher.localesTestValue = [systemLocale];
  tester.platformDispatcher.platformBrightnessTestValue = systemBrightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final cache = CacheDatabase(NativeDatabase.memory());
  addTearDown(cache.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        httpTransportProvider.overrideWithValue(
          transport ?? FakeTransport.offline(),
        ),
        cacheDatabaseProvider.overrideWith((ref) => cache),
        if (database != null)
          dataDatabaseProvider.overrideWith((ref) => database)
        else
          tripSummariesProvider.overrideWith(
            (ref) => loadTrips == null ? Future.value(trips) : loadTrips(),
          ),
        deviceTimezoneProvider.overrideWith((ref) => deviceTimezone),
        todayProvider.overrideWithValue(() => today ?? LocalDate(2026, 3, 10)),
        scaffoldCatalogEnabledProvider.overrideWithValue(scaffoldCatalog),
      ],
      child: const ItinereaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the settings screen from the home screen.
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('openSettings')));
  await tester.pumpAndSettle();
}

/// Taps the widget with the given key and waits for the app to settle.
Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}
