// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/sync/hlc.dart';

const _deviceA = EntityId('01900000-0000-7000-8000-00000000000a');
const _deviceB = EntityId('01900000-0000-7000-8000-00000000000b');

void main() {
  // A wall clock the test moves by hand.
  late DateTime wall;
  DateTime now() => wall;
  HlcClock clock(EntityId device) => HlcClock(deviceId: device, wallClock: now);

  setUp(() => wall = DateTime.utc(2026, 3, 12, 9));

  group('text form', () {
    test('round-trips through its text', () {
      final value = HlcTimestamp(
        wallMillis: wall.millisecondsSinceEpoch,
        counter: 42,
        deviceId: _deviceA,
      );

      expect(HlcTimestamp.parse(value.text), value);
      expect(
        value.text.value,
        '019ce1463280:002a:01900000-0000-7000-8000-00000000000a',
      );
    });

    test('the alphabetical order of the texts is the order of the values', () {
      final values = [
        for (final millis in [1, 2, 0x100, 0xFFFFFFFFFFFF])
          for (final counter in [0, 9, 0x10, 0xFFFF])
            for (final device in [_deviceA, _deviceB])
              HlcTimestamp(
                wallMillis: millis,
                counter: counter,
                deviceId: device,
              ),
      ];
      final byValue = [...values]..sort();
      final byText = [...values]..sort((a, b) => a.text.compareTo(b.text));

      expect(byText, byValue);
    });

    test('rejects malformed texts', () {
      for (final text in ['', 'abc', '019ce13b7880:2a:dev', 'x:0000:dev']) {
        expect(
          () => HlcTimestamp.parse(Hlc(text)),
          throwsFormatException,
          reason: text,
        );
      }
    });
  });

  group('local changes', () {
    test('follow the wall clock when it moves forward', () {
      final a = clock(_deviceA);

      final first = a.send();
      wall = wall.add(const Duration(seconds: 1));
      final second = a.send();

      expect(first.counter, 0);
      expect(second.wallMillis, wall.millisecondsSinceEpoch);
      expect(second.counter, 0);
      expect(second.compareTo(first), isPositive);
    });

    test('in the same millisecond are told apart by the counter', () {
      final a = clock(_deviceA);

      final values = [for (var i = 0; i < 5; i++) a.send()];

      expect(values.map((v) => v.counter), [0, 1, 2, 3, 4]);
      expect(values.map((v) => v.wallMillis).toSet(), hasLength(1));
    });

    test('keep growing when the wall clock goes backwards', () {
      final a = clock(_deviceA);

      final before = a.send();
      wall = wall.subtract(const Duration(hours: 3));
      final after = a.send();

      expect(after.compareTo(before), isPositive);
      expect(after.wallMillis, before.wallMillis);
    });

    test('borrow the next millisecond when the counter is exhausted', () {
      final a = HlcClock(
        deviceId: _deviceA,
        wallClock: now,
        last: HlcTimestamp(
          wallMillis: wall.millisecondsSinceEpoch,
          counter: HlcTimestamp.maxCounter,
          deviceId: _deviceA,
        ),
      );

      final next = a.send();

      expect(next.wallMillis, wall.millisecondsSinceEpoch + 1);
      expect(next.counter, 0);
    });
  });

  group('changes from other devices', () {
    test('a change made after receiving one is later than it', () {
      final a = clock(_deviceA);
      final b = clock(_deviceB);
      // Device B is 10 minutes ahead.
      wall = wall.add(const Duration(minutes: 10));
      final fromB = b.send();
      wall = wall.subtract(const Duration(minutes: 10));

      a.receive(fromB);
      final local = a.send();

      expect(local.compareTo(fromB), isPositive);
      expect(local.deviceId, _deviceA);
    });

    test('two devices never produce the same value', () {
      final a = clock(_deviceA);
      final b = clock(_deviceB);

      final fromA = a.send();
      final fromB = b.send();

      expect(fromA.wallMillis, fromB.wallMillis);
      expect(fromA.counter, fromB.counter);
      expect(fromA == fromB, isFalse);
      expect(fromA.compareTo(fromB), isNot(0));
    });

    test('an older value received later does not move the clock back', () {
      final a = clock(_deviceA);
      final b = clock(_deviceB);
      final old = b.send();
      wall = wall.add(const Duration(hours: 1));
      final recent = a.send();

      final afterReceive = a.receive(old);

      expect(afterReceive.compareTo(recent), isPositive);
    });
  });

  group('wrong clocks (PRD 9.5)', () {
    test('a difference within 24 hours is accepted', () {
      final a = clock(_deviceA);
      final remote = HlcTimestamp(
        wallMillis: wall
            .add(const Duration(hours: 23, minutes: 59))
            .millisecondsSinceEpoch,
        counter: 0,
        deviceId: _deviceB,
      );

      expect(a.isSkewed(remote), isFalse);
    });

    test('a difference of more than 24 hours is reported, both ways', () {
      final a = clock(_deviceA);
      HlcTimestamp at(Duration offset) => HlcTimestamp(
        wallMillis: wall.add(offset).millisecondsSinceEpoch,
        counter: 0,
        deviceId: _deviceB,
      );

      expect(a.isSkewed(at(const Duration(hours: 24, minutes: 1))), isTrue);
      expect(a.isSkewed(at(const Duration(hours: -25))), isTrue);
      expect(
        a.skewOf(at(const Duration(hours: 30))),
        const Duration(hours: 30),
      );
    });
  });
}
