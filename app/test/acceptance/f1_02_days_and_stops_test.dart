// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F1.2 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(M3 F1.2): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.2 Days and stops', () {
    test(
      'a stop found by name shows hours and contacts when OSM has them, and leaves the fields empty and editable when it does not',
      () {},
      skip: 'M3 – F1.2',
    );

    test(
      'reordering is saved at once and works offline',
      () {},
      skip: 'M3 – F1.2',
    );

    test(
      'moving a stop to another day updates the times of both days',
      () {},
      skip: 'M3 – F1.2',
    );
  });
}
