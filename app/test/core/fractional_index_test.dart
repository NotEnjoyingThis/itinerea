// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/sync/fractional_index.dart';

/// One item of a list as a device sees it: an identifier and an order key.
typedef _Item = ({String id, String key});

List<String> _order(Iterable<_Item> items) =>
    (items.toList()
          ..sort((a, b) => FractionalIndex.compare(a.key, a.id, b.key, b.id)))
        .map((item) => item.id)
        .toList();

void main() {
  group('a key between two others', () {
    test('sorts after the first and before the second', () {
      const pairs = <(String?, String?)>[
        (null, null),
        (null, 'V'),
        ('V', null),
        ('A', 'B'),
        ('A', 'A1'),
        ('A1', 'A2'),
        ('Az', 'B'),
        ('zz', null),
        (null, '1'),
        (null, '01'),
        ('0001', '0002'),
        ('V', 'V0001'),
      ];
      for (final (after, before) in pairs) {
        final key = FractionalIndex.between(after, before);

        expect(FractionalIndex.isValid(key), isTrue, reason: '$after $before');
        if (after != null) {
          expect(key.compareTo(after), isPositive, reason: '$after < $key');
        }
        if (before != null) {
          expect(key.compareTo(before), isNegative, reason: '$key < $before');
        }
      }
    });

    test('exists after 1,000 insertions at the same place', () {
      // Always insert right after the first item: the worst case for the
      // length of the keys.
      final first = FractionalIndex.between(null, null);
      var next = FractionalIndex.between(first, null);
      for (var i = 0; i < 1000; i++) {
        final key = FractionalIndex.between(first, next);
        expect(key.compareTo(first), isPositive);
        expect(key.compareTo(next), isNegative);
        next = key;
      }
    });

    test('keeps a list in order through random insertions and moves', () {
      final random = Random(20261114);
      final keys = <String>[];
      for (var step = 0; step < 2000; step++) {
        if (keys.length > 2 && random.nextInt(4) == 0) {
          keys.removeAt(random.nextInt(keys.length));
        }
        final position = random.nextInt(keys.length + 1);
        final key = FractionalIndex.between(
          position == 0 ? null : keys[position - 1],
          position == keys.length ? null : keys[position],
        );
        keys.insert(position, key);
      }

      expect(keys, [...keys]..sort());
      expect(keys.toSet(), hasLength(keys.length));
      expect(keys.every(FractionalIndex.isValid), isTrue);
    });

    test('appending 500 items keeps the keys short', () {
      final keys = FractionalIndex.spread(500);

      expect(keys, [...keys]..sort());
      expect(keys.map((key) => key.length).reduce(max), lessThan(120));
    });

    test('does not exist between equal or reversed keys', () {
      expect(() => FractionalIndex.between('V', 'V'), throwsArgumentError);
      expect(() => FractionalIndex.between('W', 'V'), throwsArgumentError);
    });

    test('refuses malformed keys', () {
      for (final key in ['', 'A0', '0', 'a-b', 'é']) {
        expect(FractionalIndex.isValid(key), isFalse, reason: key);
        expect(() => FractionalIndex.between(key, null), throwsArgumentError);
        expect(() => FractionalIndex.between(null, key), throwsArgumentError);
      }
    });
  });

  group('two devices offline (PRD 9.5)', () {
    // Both devices start from the same day: Uffizi, then Duomo.
    const uffizi = (id: 'stop-uffizi', key: 'G');
    const duomo = (id: 'stop-duomo', key: 'k');

    test('inserting at the same place gives both the same key', () {
      final onPhone = FractionalIndex.between(uffizi.key, duomo.key);
      final onLaptop = FractionalIndex.between(uffizi.key, duomo.key);

      expect(onPhone, onLaptop);
    });

    test('the identifier decides, so both devices show the same order', () {
      final lunch = (
        id: 'stop-b-lunch',
        key: FractionalIndex.between(uffizi.key, duomo.key),
      );
      final market = (
        id: 'stop-a-market',
        key: FractionalIndex.between(uffizi.key, duomo.key),
      );
      expect(lunch.key, market.key);

      // After syncing, each device holds the same four stops, but received
      // them in a different order.
      final phone = _order([uffizi, lunch, duomo, market]);
      final laptop = _order([market, duomo, uffizi, lunch]);

      expect(phone, laptop);
      expect(phone, [
        'stop-uffizi',
        'stop-a-market',
        'stop-b-lunch',
        'stop-duomo',
      ]);
    });

    test('the tie-break does not depend on which device sorts first', () {
      final random = Random(7);
      final items = <_Item>[
        for (var i = 0; i < 40; i++)
          (id: 'stop-${i.toString().padLeft(2, '0')}', key: 'V${i % 4 + 1}'),
      ];
      final expected = _order(items);

      for (var device = 0; device < 20; device++) {
        expect(_order([...items]..shuffle(random)), expected);
      }
    });

    test('moves made on two devices keep one coherent order', () {
      const a = (id: 'a', key: 'A');
      const b = (id: 'b', key: 'G');
      // Stops "c" and "d" come later in the day. The phone moves "d" between
      // "a" and "b"; the laptop moves "c" there.
      final movedD = (id: 'd', key: FractionalIndex.between(a.key, b.key));
      final movedC = (id: 'c', key: FractionalIndex.between(a.key, b.key));

      final phone = _order([a, b, movedC, movedD]);
      final laptop = _order([movedD, movedC, b, a]);

      expect(phone, laptop);
      expect(phone, ['a', 'c', 'd', 'b']);
    });
  });
}
