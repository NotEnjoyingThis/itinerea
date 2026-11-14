// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/ids.dart';

/// A generator that always returns the same byte, to see which bits of the
/// identifier are random and which are fixed by RFC 9562.
class _ConstantRandom implements Random {
  _ConstantRandom(this.byte);

  final int byte;

  @override
  int nextInt(int max) => byte % max;

  @override
  bool nextBool() => byte.isOdd;

  @override
  double nextDouble() => 0;
}

void main() {
  group('UUID version 7 (RFC 9562)', () {
    test('has the canonical 8-4-4-4-12 lower-case form', () {
      final id = EntityId.generate();

      expect(
        id.value,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(id.isValid, isTrue);
    });

    test('carries version 7 and the RFC variant, whatever the random bits', () {
      for (final byte in [0x00, 0xff, 0x5a, 0xa5]) {
        final id = EntityId.generate(random: _ConstantRandom(byte)).value;

        expect(id[14], '7', reason: 'version nibble');
        expect('89ab'.contains(id[19]), isTrue, reason: 'variant bits 10');
      }
    });

    test('starts with the Unix time in milliseconds, big-endian', () {
      // Example of RFC 9562, appendix A.6: Tuesday 22 February 2022,
      // 14:22:22 -05:00 is 0x017F22E279B0 milliseconds.
      final instant = DateTime.fromMillisecondsSinceEpoch(
        0x017F22E279B0,
        isUtc: true,
      );

      final id = EntityId.generate(now: instant);

      expect(id.value.substring(0, 13), '017f22e2-79b0');
      expect(id.timestamp, instant);
    });

    test('reproduces the test vector of RFC 9562, appendix A.6', () {
      // rand_a = 0xCC3, rand_b = 0x18C4DC0C0C07398F: the bytes after the
      // timestamp are 7C C3 98 C4 DC 0C 0C 07 39 8F once version and variant
      // are set, so the random source must supply these bytes.
      final bytes = [
        0, 0, 0, 0, 0, 0, // overwritten by the timestamp
        0xCC, 0xC3, 0x18, 0xC4, 0xDC, 0x0C, 0x0C, 0x07, 0x39, 0x8F,
      ];
      var next = 0;
      final id = EntityId.generate(
        now: DateTime.fromMillisecondsSinceEpoch(0x017F22E279B0, isUtc: true),
        random: _Scripted(() => bytes[next++]),
      );

      expect(id.value, '017f22e2-79b0-7cc3-98c4-dc0c0c07398f');
    });

    test('uses 74 random bits: only version and variant are fixed', () {
      final zeros = EntityId.generate(
        now: DateTime.utc(2026),
        random: _ConstantRandom(0x00),
      ).value;
      final ones = EntityId.generate(
        now: DateTime.utc(2026),
        random: _ConstantRandom(0xff),
      ).value;

      expect(zeros.substring(14), '7000-8000-000000000000');
      expect(ones.substring(14), '7fff-bfff-ffffffffffff');
    });

    test('identifiers created later sort later', () {
      final earlier = EntityId.generate(now: DateTime.utc(2026, 3, 12, 9));
      final later = EntityId.generate(now: DateTime.utc(2026, 3, 12, 9, 0, 1));

      expect(earlier.value.compareTo(later.value), isNegative);
    });

    test('10,000 identifiers of the same millisecond are all different', () {
      final now = DateTime.utc(2026, 11, 14);
      final ids = {for (var i = 0; i < 10000; i++) EntityId.generate(now: now)};

      expect(ids, hasLength(10000));
    });

    test('rejects times outside the 48 bits of the format', () {
      expect(
        () => EntityId.generate(now: DateTime.utc(1969, 12, 31)),
        throwsArgumentError,
      );
    });

    test('recognises what is not a UUID version 7', () {
      const notV7 = [
        '',
        'not-a-uuid',
        '017f22e2-79b0-4cc3-98c4-dc0c0c07398f', // version 4
        '017f22e2-79b0-7cc3-18c4-dc0c0c07398f', // wrong variant
        '017F22E2-79B0-7CC3-98C4-DC0C0C07398F', // upper case
      ];
      for (final value in notV7) {
        expect(EntityId(value).isValid, isFalse, reason: value);
      }
      expect(() => const EntityId('nope').timestamp, throwsFormatException);
    });
  });
}

/// A generator that returns the bytes given by a function, in order.
class _Scripted implements Random {
  _Scripted(this._next);

  final int Function() _next;

  @override
  int nextInt(int max) => _next() % max;

  @override
  bool nextBool() => _next().isOdd;

  @override
  double nextDouble() => 0;
}
