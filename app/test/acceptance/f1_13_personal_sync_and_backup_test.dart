// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F1.13 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(M6 F1.13): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.13 Personal sync space and backup', () {
    test(
      'a trip created offline without a space syncs correctly once the user connects a space',
      () {},
      skip: 'M6 – F1.13',
    );

    test(
      'disconnecting the space leaves the trips on the device',
      () {},
      skip: 'M6 – F1.13',
    );

    test(
      'a backup restored on another device reproduces the same trip, attachments included',
      () {},
      skip: 'M6 – F1.13',
    );
  });
}
