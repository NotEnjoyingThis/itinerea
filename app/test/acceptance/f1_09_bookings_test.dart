// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F1.9 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(M5 F1.9): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.9 Bookings (manual entry)', () {
    test(
      'a hotel from the 10th to the 13th appears as the lodging of the 10th, 11th and 12th, with check-in on the 10th and check-out on the 13th',
      () {},
      skip: 'M5 – F1.9',
    );

    test(
      'a booking has a fixed time in the recalculation',
      () {},
      skip: 'M5 – F1.9',
    );

    test(
      'a flight entered by hand creates a plane leg with fixed times between two stops created for the airports',
      () {},
      skip: 'M5 – F1.9',
    );
  });
}
