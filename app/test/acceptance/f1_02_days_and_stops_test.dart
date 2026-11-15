// SPDX-License-Identifier: GPL-3.0-or-later

// Acceptance criteria of F1.2 (PRD 6) and where each one is tested.
//
// 2. "Reordering is saved at once and works offline":
//    test/features/day/trip_screen_test.dart drags a stop and reads the new
//    order back from the database right away; nothing in the flow uses the
//    network. test/features/day/stop_repository_test.dart covers the same
//    rule without the screen, including two stops with the same order key.
//
// The other two need what comes in the next steps of milestone M3: the place
// search (criterion 1) and the times of the day (criterion 3).

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.2 Days and stops', () {
    // TODO(M3 F1.2): place search and details from OpenStreetMap.
    test(
      'a stop found by name shows hours and contacts when OSM has them, and leaves the fields empty and editable when it does not',
      () {},
      skip: 'M3 – F1.2',
    );

    // TODO(M3 F1.3): times of the day.
    test(
      'moving a stop to another day updates the times of both days',
      () {},
      skip: 'M3 – F1.3',
    );
  });
}
