// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F1.6 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(M3 F1.6): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.6 Alternatives (plans A, B, C, D)', () {
    test(
      'switching a stop from plan A to plan B recalculates the following times, and the budget changes only if plan B has a booking or a recorded expense',
      () {},
      skip: 'M3 – F1.6',
    );

    test(
      'going back to plan A restores everything as it was',
      () {},
      skip: 'M3 – F1.6',
    );

    test(
      'an expense already recorded for plan A stays in the budget after switching to plan B',
      () {},
      skip: 'M3 – F1.6',
    );
  });
}
