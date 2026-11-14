// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F2.3 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(Fase 2 F2.3): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F2.3 Automatic booking import', () {
    test(
      'a flight confirmation with structured data creates the booking with the right times, airports and code, even in airplane mode',
      () {},
      skip: 'Fase 2 – F2.3',
    );

    test(
      'the screenshot of a boarding pass with a BCBP code creates flight, date, seat and booking code',
      () {},
      skip: 'Fase 2 – F2.3',
    );

    test(
      'a file that cannot be read opens the manual form with the file already attached',
      () {},
      skip: 'Fase 2 – F2.3',
    );
  });
}
