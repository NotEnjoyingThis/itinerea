// SPDX-License-Identifier: GPL-3.0-or-later

// Placeholder acceptance tests for F1.8 (PRD 6). Scaffolding only: every
// test is skipped and names the acceptance criterion it will check.
// TODO(M5 F1.8): write the tests when the feature is built.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F1.8 Tickets and attachments', () {
    test('an attached PDF opens in airplane mode', () {}, skip: 'M5 – F1.8');

    test(
      'a QR code shown in the ticket view is readable by a standard reader',
      () {},
      skip: 'M5 – F1.8',
    );
  });
}
