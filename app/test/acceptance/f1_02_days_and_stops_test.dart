// SPDX-License-Identifier: GPL-3.0-or-later

// Acceptance criteria of F1.2 (PRD 6) and where each one is tested.
//
// 1. "A stop searched by name shows hours and contacts when OSM has them.
//    When it does not, the fields stay empty and editable, without errors":
//    test/features/day/place_search_test.dart adds the Uffizi from the
//    search and finds hours, phone and website in its details, then adds a
//    square that OpenStreetMap knows nothing about, finds the fields empty,
//    no message, and writes a phone number. Photon and Nominatim are
//    answered by a fake shaped on real answers (test/support/
//    osm_samples.dart); test/core/providers/ covers reading those answers.
//
// 2. "Reordering is saved at once and works offline":
//    test/features/day/trip_screen_test.dart drags a stop and reads the new
//    order back from the database right away; nothing in the flow uses the
//    network. test/features/day/stop_repository_test.dart covers the same
//    rule without the screen, including two stops with the same order key.
//
// Criterion 3 needs the times of the day, the next step of milestone M3.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.2 Days and stops', () {
    // TODO(M3 F1.3): times of the day.
    test(
      'moving a stop to another day updates the times of both days',
      () {},
      skip: 'M3 – F1.3',
    );
  });
}
