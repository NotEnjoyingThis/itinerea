// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/net/throttle.dart';

void main() {
  late DateTime clock;
  late List<Duration> waits;

  // A throttle on a clock that moves only when the test says so, or when
  // the throttle waits.
  Throttle throttle(Duration interval) => Throttle(
    interval,
    now: () => clock,
    wait: (duration) async {
      waits.add(duration);
      clock = clock.add(duration);
    },
  );

  setUp(() {
    clock = DateTime.utc(2026, 11, 16, 12);
    waits = [];
  });

  test('the first request starts at once', () async {
    expect(await throttle(const Duration(seconds: 1)).run(() async => 7), 7);
    expect(waits, isEmpty);
  });

  test('requests go one at a time, at least the interval apart', () async {
    final queue = throttle(const Duration(milliseconds: 1100));
    var running = 0;
    var mostAtOnce = 0;
    final starts = <DateTime>[];
    Future<int> request(int number) => queue.run(() async {
      starts.add(clock);
      mostAtOnce = max(mostAtOnce, ++running);
      // The answer takes 200 ms.
      await Future<void>.delayed(Duration.zero);
      clock = clock.add(const Duration(milliseconds: 200));
      running--;
      return number;
    });

    final answers = await Future.wait([request(1), request(2), request(3)]);

    expect(answers, [1, 2, 3]);
    expect(mostAtOnce, 1);
    expect(starts[1].difference(starts[0]), const Duration(milliseconds: 1100));
    expect(starts[2].difference(starts[1]), const Duration(milliseconds: 1100));
    expect(waits, [
      const Duration(milliseconds: 900),
      const Duration(milliseconds: 900),
    ]);
  });

  test('no wait when the interval has already passed', () async {
    final queue = throttle(const Duration(seconds: 1));
    await queue.run(() async {});
    clock = clock.add(const Duration(seconds: 5));

    await queue.run(() async {});

    expect(waits, isEmpty);
  });

  test('a failed request does not stop the next ones', () async {
    final queue = throttle(const Duration(seconds: 1));

    final failed = queue.run<int>(() async => throw StateError('down'));
    final next = queue.run(() async => 2);

    await expectLater(failed, throwsStateError);
    expect(await next, 2);
  });
}
