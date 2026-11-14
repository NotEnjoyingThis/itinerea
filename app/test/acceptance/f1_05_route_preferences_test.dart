// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F1.5 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(M4 F1.5): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.5 Routes with preferences', () {
    test(
      'with "avoid motorways" on, the calculated route uses no motorway when an alternative exists',
      () {},
      skip: 'M4 – F1.5',
    );

    test(
      'a route edited by hand stays saved and is recalculated only when the user asks',
      () {},
      skip: 'M4 – F1.5',
    );
  });
}
