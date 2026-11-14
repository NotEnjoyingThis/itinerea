// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F2.1 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(Fase 2 F2.1): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F2.1 Collaboration', () {
    test(
      'two editors changing different stops of the same day offline both find their changes after syncing',
      () {},
      skip: 'Fase 2 – F2.1',
    );

    test(
      'a viewer cannot change anything, not even offline: editing is hidden and the sync space rejects writes',
      () {},
      skip: 'Fase 2 – F2.1',
    );

    test(
      'the Itinerea Sync Server installs with a single Docker command following the repository documentation',
      () {},
      skip: 'Fase 2 – F2.1',
    );
  });
}
