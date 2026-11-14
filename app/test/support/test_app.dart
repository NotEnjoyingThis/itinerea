// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/app.dart';
import 'package:itinerea/features/scaffold/scaffold_catalog_screen.dart';
import 'package:itinerea/features/trips/trip_list.dart';
import 'package:material_ui/material_ui.dart';

/// Starts the whole app for a widget test, with the trips given instead of
/// the database of the device.
///
/// [trips] may also be a function that throws, to show the error state.
Future<void> pumpItinerea(
  WidgetTester tester, {
  Locale systemLocale = const Locale('en'),
  Brightness systemBrightness = Brightness.light,
  List<TripSummary> trips = const [],
  Future<List<TripSummary>> Function()? loadTrips,
  bool scaffoldCatalog = false,
}) async {
  tester.platformDispatcher.localesTestValue = [systemLocale];
  tester.platformDispatcher.platformBrightnessTestValue = systemBrightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripSummariesProvider.overrideWith(
          (ref) => loadTrips == null ? Future.value(trips) : loadTrips(),
        ),
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
