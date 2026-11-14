// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F1.1 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(M3 F1.1): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.1 Trip creation', () {
    test(
      'a basic trip (name, destination, dates) is created in under 2 minutes and at most 4 screens',
      () {},
      skip: 'M3 – F1.1',
    );

    test(
      'changing the dates adds or removes days, and the app asks whether to move or delete the stops of a removed day',
      () {},
      skip: 'M3 – F1.1',
    );

    test(
      'in a mixed trip the roadtrip functions appear only in the days of the roadtrip segment',
      () {},
      skip: 'M3 – F1.1',
    );

    test(
      'a trip created with only a number of days can be planned, and setting the start date later gives each day its date without losing stops',
      () {},
      skip: 'M3 – F1.1',
    );
  });
}
