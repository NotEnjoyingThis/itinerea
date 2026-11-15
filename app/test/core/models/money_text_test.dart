// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/money_text.dart';
import 'package:itinerea/features/day/stop_detail_panel.dart';
import 'package:itinerea/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('reading an amount typed by a person', () {
    int? euros(String text) => MoneyText.parse(text, decimalDigits: 2);

    test('accepts the comma and the dot as decimal separator', () {
      expect(euros('12,50'), 1250);
      expect(euros('12.50'), 1250);
      expect(euros('12,5'), 1250);
      expect(euros('12'), 1200);
      expect(euros('0,05'), 5);
      expect(euros('  7,20 '), 720);
    });

    test('never goes through a floating point number', () {
      // 0.1 + 0.2 is not 0.3 in floating point; in minor units it is.
      expect(euros('0,1')! + euros('0,2')!, euros('0,3'));
      expect(euros('19.99'), 1999);
      expect(euros('1234567890,99'), 123456789099);
    });

    test('respects the decimals of the currency', () {
      expect(MoneyText.parse('3000', decimalDigits: 0), 3000);
      expect(MoneyText.parse('3000,5', decimalDigits: 0), isNull);
      expect(MoneyText.parse('1,234', decimalDigits: 3), 1234);
      expect(euros('1,234'), isNull, reason: 'three decimals for euros');
    });

    test('refuses what is not clearly an amount', () {
      for (final text in [
        '',
        ' ',
        '-5',
        '+5',
        '12,5,0',
        '1.234,50',
        '12 50',
        'dodici',
        '12€',
        ',50',
        '12,',
        '1e3',
        '9999999999999',
      ]) {
        expect(euros(text), isNull, reason: '"$text"');
      }
    });
  });

  group('writing an amount for an edit field', () {
    test('puts the separator before the decimals', () {
      expect(MoneyText.format(1250, decimalDigits: 2), '12.50');
      expect(MoneyText.format(5, decimalDigits: 2), '0.05');
      expect(MoneyText.format(1250, decimalDigits: 2, separator: ','), '12,50');
      expect(MoneyText.format(3000, decimalDigits: 0), '3000');
      expect(MoneyText.format(-1250, decimalDigits: 2), '-12.50');
    });

    test('what is written reads back as the same amount', () {
      for (final amount in [0, 1, 99, 100, 1250, 999999]) {
        for (final separator in ['.', ',']) {
          final text = MoneyText.format(
            amount,
            decimalDigits: 2,
            separator: separator,
          );
          expect(MoneyText.parse(text, decimalDigits: 2), amount);
        }
      }
    });
  });

  group('durations', () {
    for (final (locale, expected) in [
      (const Locale('en'), ['0 min', '45 min', '1 h', '1 h 30 min', '24 h']),
      (const Locale('it'), ['0 min', '45 min', '1 h', '1 h 30 min', '24 h']),
    ]) {
      test('are written in hours and minutes ($locale)', () {
        final l10n = lookupAppLocalizations(locale);

        expect([
          for (final minutes in [0, 45, 60, 90, 1440])
            formatDuration(l10n, minutes),
        ], expected);
      });
    }
  });
}
