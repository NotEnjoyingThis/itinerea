// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/expense.dart';
import 'package:itinerea/core/models/expense_check.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/models/money.dart';
import 'package:itinerea/core/models/place.dart';

const _anna = EntityId('participant-anna');
const _marco = EntityId('participant-marco');
const _luca = EntityId('participant-luca');

Split _split(SplitType type, List<int> values) => Split(
  type: type,
  entries: [
    for (final (index, value) in values.indexed)
      SplitEntry(participantId: [_anna, _marco, _luca][index], value: value),
  ],
);

const _hundredEuros = Money(amountMinor: 10000, currency: 'EUR');

void main() {
  group('split of an expense', () {
    test('equal parts fit any amount', () {
      for (final amount in [0, 1, 10000, 999999]) {
        expect(
          ExpenseCheck.problemOf(
            amount: Money(amountMinor: amount, currency: 'EUR'),
            split: _split(SplitType.equal, [0, 0, 0]),
          ),
          isNull,
        );
      }
    });

    test('percentages must add up to 100, whatever the amount', () {
      expect(
        ExpenseCheck.problemOf(
          amount: _hundredEuros,
          split: _split(SplitType.percent, [3334, 3333, 3333]),
        ),
        isNull,
      );
      for (final values in [
        [5000, 4999],
        [5000, 5001],
        [10000, 1],
      ]) {
        expect(
          ExpenseCheck.problemOf(
            amount: _hundredEuros,
            split: _split(SplitType.percent, values),
          ),
          SplitProblem.percentagesDoNotAddUp,
          reason: '$values',
        );
      }
    });

    test('shares fit any amount as long as someone has a share', () {
      expect(
        ExpenseCheck.problemOf(
          amount: _hundredEuros,
          split: _split(SplitType.shares, [2, 1, 0]),
        ),
        isNull,
      );
      expect(
        ExpenseCheck.problemOf(
          amount: _hundredEuros,
          split: _split(SplitType.shares, [0, 0]),
        ),
        SplitProblem.nobodyToCharge,
      );
    });

    test('exact amounts must add up to the amount, to the cent', () {
      expect(
        ExpenseCheck.problemOf(
          amount: _hundredEuros,
          split: _split(SplitType.exact, [3334, 3333, 3333]),
        ),
        isNull,
      );
      for (final values in [
        [3333, 3333, 3333],
        [6000, 4001],
        [10001],
      ]) {
        expect(
          ExpenseCheck.problemOf(
            amount: _hundredEuros,
            split: _split(SplitType.exact, values),
          ),
          SplitProblem.exactAmountsDoNotAddUp,
          reason: '$values',
        );
      }
    });

    test('a split that names nobody, or has a negative part, needs review', () {
      for (final type in SplitType.values) {
        expect(
          ExpenseCheck.problemOf(
            amount: _hundredEuros,
            split: _split(type, []),
          ),
          SplitProblem.nobodyToCharge,
          reason: type.name,
        );
        expect(
          ExpenseCheck.problemOf(
            amount: _hundredEuros,
            split: _split(type, [15000, -5000]),
          ),
          SplitProblem.negativePart,
          reason: type.name,
        );
      }
    });

    test('fields that cannot be read are marked for review, not an error', () {
      final unreadable = <Map<String, Object?>>[
        {},
        {'amount': _hundredEuros.toJson()},
        {'amount': _hundredEuros.toJson(), 'split': 'half each'},
        {
          'amount': {'amountMinor': 100.5, 'currency': 'EUR'},
          'split': _split(SplitType.equal, [0]).toJson(),
        },
        {
          'amount': _hundredEuros.toJson(),
          'split': {'type': 'byWeight', 'entries': <Object?>[]},
        },
      ];
      for (final fields in unreadable) {
        expect(
          ExpenseCheck.problemOfFields(fields),
          SplitProblem.unreadable,
          reason: '$fields',
        );
        expect(ExpenseCheck.needsReview(fields), isTrue);
      }
    });
  });

  group('embedded objects as JSON', () {
    test('an amount is never read from a decimal number', () {
      expect(
        () => Money.fromJson({'amountMinor': 12.5, 'currency': 'EUR'}),
        throwsFormatException,
      );
      expect(
        Money.fromJson({'amountMinor': 3000, 'currency': 'JPY'}).toJson(),
        {'amountMinor': 3000, 'currency': 'JPY'},
      );
    });

    test('unknown keys survive reading and writing, at every level', () {
      final place = {
        'name': 'Uffizi',
        'coordinates': {'lat': 43.7687, 'lon': 11.2553, 'altitudeM': 50},
        'osmId': 'way/123',
        'wheelchair': 'yes',
      };
      final split = {
        'type': 'exact',
        'rounding': 'toPayer',
        'entries': [
          {'participantId': 'participant-anna', 'value': 100, 'label': 'adult'},
        ],
      };
      final money = {'amountMinor': 100, 'currency': 'EUR', 'display': '1,00'};

      expect(PlaceSnapshot.fromJson(place).toJson(), place);
      expect(Split.fromJson(split).toJson(), split);
      expect(Money.fromJson(money).toJson(), money);
    });

    test('a known key always wins over an unknown one with the same name', () {
      const money = Money(
        amountMinor: 500,
        currency: 'EUR',
        unknown: {'currency': 'XXX', 'note': 'kept'},
      );

      expect(money.toJson(), {
        'amountMinor': 500,
        'currency': 'EUR',
        'note': 'kept',
      });
    });

    test('missing or mistyped required values are rejected', () {
      expect(
        () => PlaceSnapshot.fromJson({'name': 'x'}),
        throwsFormatException,
      );
      expect(
        () => PlaceSnapshot.fromJson({
          'name': 'x',
          'coordinates': {'lat': '43', 'lon': 11},
        }),
        throwsFormatException,
      );
      expect(
        () => Split.fromJson({
          'type': 'equal',
          'entries': ['anna'],
        }),
        throwsFormatException,
      );
    });
  });
}
