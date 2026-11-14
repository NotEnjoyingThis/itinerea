// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F1.10 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(M5 F1.10): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.10 Budget and expenses (personal)', () {
    test(
      "an expense of 3,000 JPY on 12 March uses the exchange rate of 12 March, not today's",
      () {},
      skip: 'M5 – F1.10',
    );

    test(
      'bookings with a cost appear in the budget without being entered twice',
      () {},
      skip: 'M5 – F1.10',
    );
  });
}
