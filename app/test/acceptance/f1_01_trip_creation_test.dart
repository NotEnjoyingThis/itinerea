// SPDX-License-Identifier: GPL-3.0-or-later

// Acceptance criteria of F1.1 (PRD 6) and where each one is tested.
//
// 1. "A basic trip is created in under 2 minutes and at most 4 screens":
//    test/features/trips/new_trip_screen_test.dart creates a trip in three
//    steps. The two minutes are checked by hand before a release.
// 4. "A trip created with only a number of days can be planned; setting the
//    start date later gives each day its date without losing stops":
//    test/features/trips/trip_repository_test.dart and trip_plan_test.dart.
//
// Criteria 2 and 3 are tested as rules and on the database (the same two
// files), but not yet on screen: the screens that show them arrive with the
// day screen. They stay here, skipped, until then.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.1 Trip creation', () {
    // TODO(M3 F1.1): the dialog that asks what to do with the stops.
    test(
      'changing the dates adds or removes days, and the app asks whether to move or delete the stops of a removed day (on screen)',
      () {},
      skip: 'M3 – F1.1',
    );

    // TODO(M3 F1.1): the day menu "from here: roadtrip" (FL8) and the
    // roadtrip functions, which do not exist before phase 2.
    test(
      'in a mixed trip the roadtrip functions appear only in the days of the roadtrip segment (on screen)',
      () {},
      skip: 'M3 – F1.1',
    );
  });
}
