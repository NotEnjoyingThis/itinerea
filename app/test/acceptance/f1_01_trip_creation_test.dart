// SPDX-License-Identifier: GPL-3.0-or-later

// Acceptance criteria of F1.1 (PRD 6) and where each one is tested.
//
// 1. "A basic trip is created in under 2 minutes and at most 4 screens":
//    test/features/trips/new_trip_screen_test.dart creates a trip in three
//    steps. The two minutes are checked by hand before a release.
// 2. "Changing the dates adds or removes days, and the app asks whether to
//    move or delete the stops of a removed day":
//    test/features/day/trip_screen_test.dart (group "changing the dates")
//    and test/features/trips/trip_repository_test.dart.
// 3. "In a mixed trip the roadtrip functions appear only in the days of the
//    roadtrip segment": test/features/day/trip_screen_test.dart (group
//    "kind of trip from a day on") checks that only the roadtrip days say
//    so. The roadtrip functions themselves (vehicle, fuel, stops) arrive in
//    phase 2: the test below waits for them.
// 4. "A trip created with only a number of days can be planned; setting the
//    start date later gives each day its date without losing stops":
//    test/features/day/trip_screen_test.dart ("dates given later…") and
//    test/features/trips/trip_repository_test.dart.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.1 Trip creation', () {
    // TODO(Fase 2 F2.6): vehicle, fuel and stops only in roadtrip days.
    test(
      'in a mixed trip the vehicle, fuel and stop functions appear only in the days of the roadtrip segment',
      () {},
      skip: 'Fase 2 – F2.6',
    );
  });
}
